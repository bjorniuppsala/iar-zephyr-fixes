#!/usr/bin/bash

set -x
# echo "arguments: $@"

ZEPHYRPROJECT_PATH=.
DEFAULT_IAR_TOOLCHAIN_PATH=/opt/iarsystems/bxarm/arm
IAR_TOOLCHAIN_PATH=$DEFAULT_IAR_TOOLCHAIN_PATH
DOCKER_ZEPHYRPROJECT_PATH=/workdir
DOCKER_IAR_TOOLCHAIN_PATH=/opt/iarsystems/bxarm/arm
DOCKER=docker # podman if you'd like that

# Required number of arguments
required_args=1

# Check if the number of arguments is correct
if [ "$#" -lt $required_args ]; then
  cat <<EOF
Usage: $0 <container-name> [<iar-toolchain-path>] [device]
  <container-name>       : The name to use for the docker container
  <iar-toolchain-path>   : Directory where the arm-directory of your iar-toolchain is
                           (default: $DEFAULT_IAR_TOOLCHAIN_PATH)
  device                 : Optional device mount that is needed if you want to run on HW

* Starts a new or resumes an existing docker container with the name <container-name>.
* $0 must be run from the directory where zephyr was initialized. 
* If _device_ is supplied /dev/bus/usb and /dev/ttyACM0 will be mounted in the container
* The device must already be plugged in or the mount will fail

EOF
  exit 1
fi;

DOCKER_CONTAINER_NAME=$1
DEVICE=
shift
# Loop until there are no more arguments
while [ "$#" -gt 0 ]; do
    ARG=$1
    shift
    if [ "x$ARG" = "xdevice" ]; then
      DEVICE="--device=/dev/bus/usb --device=/dev/ttyACM0"
      continue
    fi;
    if [ -d $(realpath $ARG)/arm/bin ]; then    
      IAR_TOOLCHAIN_PATH=$(realpath $ARG)/arm
      continue
    fi
done

if docker inspect "$DOCKER_CONTAINER_NAME" > /dev/null 2>&1; then
  echo "Found container $DOCKER_CONTAINER_NAME, using it"
  # Stop and start container if device was given 
  if [ ! -z "$DEVICE" ]; then
    echo restarting container
    $DOCKER stop $DOCKER_CONTAINER_NAME > /dev/null 2>&1
  fi
  $DOCKER start $DOCKER_CONTAINER_NAME > /dev/null 2>&1
  $DOCKER exec -it $DOCKER_CONTAINER_NAME bash -c "source iar_toolchain_env.sh && cd zephyr && bash"
  exit 0
fi

echo "Generating script for setting up ZEPHYR_TOOLCHAIN_VARIANT and IAR_TOOLCHAIN_PATH for IAR"
cat << EOF > $ZEPHYRPROJECT_PATH/iar_toolchain_env.sh
#!/usr/bin/bash
export ZEPHYR_TOOLCHAIN_VARIANT=iar
export IAR_TOOLCHAIN_PATH=$DOCKER_IAR_TOOLCHAIN_PATH
EOF

echo -n Checking that zephyr seems to be in the right place ...
if [ ! -d $ZEPHYRPROJECT_PATH/zephyr ]; then
    echo
    echo "Did not find $ZEPHYRPROJECT_PATH/zephyr"
    exit 1
else
  echo -n " $ZEPHYRPROJECT_PATH/zephyr "
fi;

echo -n Checking that iccarm seems to be in the right place ...
if [ ! -d $IAR_TOOLCHAIN_PATH/bin ]; then
    echo
    echo "Did not find $IAR_TOOLCHAIN_PATH/bin"
    exit 1
else
  echo -n " $IAR_TOOLCHAIN_PATH/bin "
fi;

echo
echo "No existing container with name $DOCKER_CONTAINER_NAME found, creating it ..."
$DOCKER pull docker.io/zephyrprojectrtos/zephyr-build:latest
$DOCKER run --name "$DOCKER_CONTAINER_NAME" \
    --restart=unless-stopped \
    --detach --tty \
	$DEVICE \
    --entrypoint /bin/sh \
    -u $(id -u):$(id -g) \
    -v "$ZEPHYRPROJECT_PATH:$DOCKER_ZEPHYRPROJECT_PATH" \
    -v "$IAR_TOOLCHAIN_PATH:/opt/iarsystems/bxarm/arm:ro" \
    docker.io/zephyrprojectrtos/zephyr-build:latest
# different user ids inside and outside docker...
# fatal: detected dubious ownership in repository at '/workdir/zephyr'
# Map user id inside docker to jenkins user id.
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" bash -c "sed -i s/user:x:1000:1000/user:x:$(id -u):$(id -g)/ /etc/passwd"
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" sudo chown -R user /home/user
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" sudo chown -R user /workdir
$DOCKER	exec "$DOCKER_CONTAINER_NAME" git config --global --add safe.directory /workdir/zephyr

# Curtsey download of jlink drive
if [ ! -z "$DEVICE" ]; then
    echo
    echo -n Installing jlink driver in the container ...
    pushd $ZEPHYRPROJECT_PATH
    rm -f JLink_*
    wget -q https://www.segger.com/downloads/jlink/JLink_Linux_V798i_x86_64.deb -X POST --post-data "accept_license_agreement=accepted&submit=Download+software"
    $DOCKER exec -u 0 $DOCKER_CONTAINER_NAME bash -c "dpkg -i JLink_Linux_V798i_x86_64.deb"
    rm -f JLink_*
    popd
    echo ok
fi;

echo
echo Testing that we can use iccarm from the expected location ...
$DOCKER exec -it $DOCKER_CONTAINER_NAME /opt/iarsystems/bxarm/arm/bin/iccarm --version

echo
echo "You are good to go! Try: west build -p -b qemu_cortex_m0 samples/hello_world && west build -t run"

$DOCKER exec -it $DOCKER_CONTAINER_NAME bash -c "source iar_toolchain_env.sh && cd zephyr && bash"

