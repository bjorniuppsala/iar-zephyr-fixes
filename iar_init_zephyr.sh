#!/bin/bash

# set -x
# echo "arguments: $*"

ZEPHYRPROJECT_PATH=.
DOCKER_ZEPHYRPROJECT_PATH=/workdir

DOCKER=docker # podman if you'd like that

# Required number of arguments
required_args=0

# Check if the number of arguments is correct
if [ "$#" -gt $required_args ]; then
  cat <<EOF
Usage: $0 
  * Does the west init and west update parts in the current directory
  * Requires that zephyr has been cloned to the current directory
EOF
exit 1
fi;

if [ ! -d $PWD/zephyr ]; then
  echo "Didn't find zephyr in the current directory"
  exit 1
fi

DOCKER_CONTAINER_NAME=iar_init_zephyr_$$

# If there happens to be a lingering container with the same name
if docker inspect "$DOCKER_CONTAINER_NAME" > /dev/null 2>&1; then
  $DOCKER stop "$DOCKER_CONTAINER_NAME" || true
  $DOCKER rm "$DOCKER_CONTAINER_NAME" || true
fi

$DOCKER pull docker.io/zephyrprojectrtos/zephyr-build:latest
$DOCKER run --name "$DOCKER_CONTAINER_NAME" \
     --restart=unless-stopped \
     --detach --tty \
     --entrypoint /bin/sh \
     -u $(id -u):$(id -g) \
     -v "$ZEPHYRPROJECT_PATH:$DOCKER_ZEPHYRPROJECT_PATH" \
     docker.io/zephyrprojectrtos/zephyr-build:latest
$DOCKER rmi $(docker images -f reference=zephyrprojectrtos/zephyr-build -f dangling=true -q) # Clean up unused images, TODO test this somehow
# different user ids inside and outside docker...
# fatal: detected dubious ownership in repository at '/workdir/zephyr'
# Map user id inside docker to jenkins user id.
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" bash -c "sed -i s/user:x:1000:1000/user:x:$(id -u):$(id -g)/ /etc/passwd"
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" sudo chown -R user /home/user
$DOCKER exec -u 0 "$DOCKER_CONTAINER_NAME" sudo chown -R user /workdir
$DOCKER	exec "$DOCKER_CONTAINER_NAME" git config --global --add safe.directory /workdir/zephyr
$DOCKER exec "$DOCKER_CONTAINER_NAME" west init -l zephyr
$DOCKER exec "$DOCKER_CONTAINER_NAME" west update

# Clean-up
$DOCKER stop "$DOCKER_CONTAINER_NAME" || true
$DOCKER rm "$DOCKER_CONTAINER_NAME" || true
