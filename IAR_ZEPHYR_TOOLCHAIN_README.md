* introduction text (Robin)
 
 Maybe something about the dependency on CMAKE_LINKER_GENERATOR ...


# Using Zephyr with IAR Toolchain

IAR is dependent on the zephyr-sdk. The easiest way of using them together is to use the [zephyrproject-rtos/docker-image](https://github.com/zephyrproject-rtos/docker-image).

* The scripts used here requires that docker is installed.
* A preview build of iccarm is required for use with Zephyr.

## Supported platforms/boards (Göran)

The following platfoms/boards are used for testing in CI and can be expected to pass twister tests `--level acceptance` using the IAR Toolchain:

* nrf52840dk/nrf52840
* mimxrt1060_evk
* qemu_cortex_m0
* qemu_cortex_m3

Additionally, the following plaforms/boards have passed twister tests `--level acceptance` using IAR Toolchain:

* frdm_mcxn947/mcxn947/cpu0
* ek_ra4e2
* 

## Limitations (Robin/Love)

* TBD

## Obtaining an IAR Toolchain (Robin/Daniel)

* TBD

## How to obtain a license tooken (Micke)

* TBD

## Current status of zephyr/tests (Göran)

* TBD

## How to feedback and report problems

Please report any issues found using [GitHub Issues](https://github.com/iarsystems/zephyr/issues).

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

### Running IAR Toolchain together with `zephyrproject-rtos/docker-image`

`Usage: zephyr/iar_run_zephyr.sh <container-name> [<iar-toolchain-path>] [device]`

* Creates a new or resumes an existing docker container as identified by `<container-name>`
* `[<iar-toolchain-path>]` (optional) is the path to an IAR toolchain
* `[device]` (optional) requires HW attached via usb that uses /dev/ttyACM0 as serial

The folling will look for a toolchain in the standard IAR install directory:

```
$ cd iar-zephyrproject
$ zephyr/iar_run_zephyr.sh spiffy-container
```

