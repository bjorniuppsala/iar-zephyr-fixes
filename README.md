This is an IAR internal fork of Zephyr for internal and partner use. It contains the required CMake/toolchain files necessary to compile, build and run zephyr projects using IAR compiler and linker. It also contains patches improving Zephyr's compatibility with non-GNU compilers, and we are aiming to upstreaming these patches.

Currently we are supporting selected ARM Cortex-M targets.
Since we are using the `CMAKE_LINKER_GENERATOR` mechanism to integrate ilink, this means that configurations and modules not supported by `CMAKE_LINKER_GENERATOR`, are not supported.
(e.g. `CONFIG_USERSPACE`)


# Using Zephyr with IAR Toolchain

IAR is dependent on the zephyr-sdk. The easiest way of using them together is to use the [zephyrproject-rtos/docker-image](https://github.com/zephyrproject-rtos/docker-image).

## Supported platforms/boards

The following platfoms/boards are used for testing in CI and can be expected to pass twister tests `--level acceptance` using the IAR Toolchain:

* `nrf52840dk/nrf52840`
* `mimxrt1060_evk`
* `qemu_cortex_m3`

Additionally, the following plaforms/boards have passed twister tests `--level acceptance` using IAR Toolchain:

* `frdm_mcxn947/mcxn947/cpu0`
* `ek_ra4e2`
* `qemu_cortex_m0`

## Limitations

* Currently `CONFIG_USERSPACE` is not working. It is disabled by default on platforms without MPU (`qemu_cortex_m0` and `qemu_cortex_m3`) and disabled by use of our own `CONFIG_TOOLCHAIN_SUPPORTS_USERSPACE` variable for other targets. Support for `CONFIG_USERSPACE` is coming.
* Currently TrustZone is not working. 
* Currently only minimallibc is supported, this means Picolibc and Newlib is not supported. There is experimental support for IARs DLib.
* Currently using the GNU Assembler for .S files
* The current method for static initialization `initialize by address_translation` is experimental and will most likely be replaced before upstream PR.
* If you get the error message ```Fatal error[LMS001]: [LMSC1020]: Timeout while initializing a connection to LMSC Daemon``` run the command `ulimit -n 1024` to limit the number of open file descriptors (LMSC-686).
* Known issue that happens rarely and randomly: ```Fatal error[LMS001]: [LMSC1085]: An error occurred in communication with the LMSC Daemon``` (LMSC-744).
Workaround using `export IAR_LMS_DAEMON_LICENSE_TOKEN_USAGE_TELEMETRY=0`

## Obtaining an IAR Toolchain

A Development version of the IAR build tools for ARM is required to work with this fork. It will be continuously updated, and you find it in the [GitHub Releases](https://github.com/iarsystems/zephyr/releases) section.

To run the tools, a *Bearer Token* is required for authentication and authorization. It will be distributed to partners together with installation instructions. If there are any issues with this, please contact our FAE team at fae.emea@iar.com and they will assist.

## Current status of zephyr/tests

Common causes for test fails:
* `CONFIG_USERSPACE` disabled makes some tests unable to build (usually filtered out by twister)
* Constants placed in RAM causes pbits placed in RAM which causes flash errors.

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
* `[device]` (optional) requires HW attached via USB that uses /dev/ttyACM0 as serial

The following will look for a toolchain in the standard IAR install directory:

```
$ cd iar-zephyrproject
$ zephyr/iar_run_zephyr.sh spiffy-container-name
```

