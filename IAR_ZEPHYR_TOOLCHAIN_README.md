# Using Zephyr with IAR Toolchain

IAR is using GNU as the ASM compiler from the Zephyr toolchain. The easiest way of using them together is to use the [zephyrproject-rtos/docker-image](https://github.com/zephyrproject-rtos/docker-image). 

* The scripts used here requires that docker is installed.
* A preview build of iccarm is required for use with Zephyr.

## Obtaining an IAR Toolchain that works with Zephyr.

```
$ tbd
```

## Using IAR Toolchain together with `zephyrproject-rtos/docker-image`

### Clone and init

`Usage: zephyr/iar_init_zephyr.sh`

The `iar_init_zephyr.sh` will do west init and west update on the cloned repository using the `zephyrproject-rtos/docker-image`.

* No parameters required

```
$ mkdir iar-zephyrproject
$ cd iar-zephyrproject
$ git clone --branch iar-4.x git@github.com:iarsystems/zephyr.git
$ zephyr/iar_init_zephyr.sh
```

### Runnign IAR Toolchain together with `zephyrproject-rtos/docker-image`

`Usage: zephyr/iar_run_zephyr.sh <container-name> [<iar-toolchain-path>] [device]`

* Creates a new or resumes an existing docker container as identified by `<container-name>`
* `[<iar-toolchain-path>]` (optional) is the path to an IAR toolchain
* `[device]` (optional) requires HW attached via usb that uses /dev/ttyACM0 as serial

The folling will look for a toolchain in the standard IAR install directory:

```
$ cd iar-zephyrproject
$ zephyr/iar_run_zephyr.sh spiffy-container
```

## Known problems and limitations

* `CONFIG_USERSPACE=y` is not supported by toolchain

## How to report problems

Please report any issues found using [GitHub Issues](https://github.com/iarsystems/zephyr/issues).

* Do we want to configure what issue types there?
* Do we want to configure labels?