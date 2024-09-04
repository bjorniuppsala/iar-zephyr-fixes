# SPDX-License-Identifier: Apache-2.0

zephyr_get(ICCARM_TOOLCHAIN_PATH)
assert(ICCARM_TOOLCHAIN_PATH "ICCARM_TOOLCHAIN_PATH is not set")

if(NOT EXISTS ${ICCARM_TOOLCHAIN_PATH})
  message(FATAL_ERROR "Nothing found at ICCARM_TOOLCHAIN_PATH: '${ICCARM_TOOLCHAIN_PATH}'")
endif()

message(STATUS "Found toolchain: IAR C/C++ Compiler for Arm (${ICCARM_TOOLCHAIN_PATH})")

# iccarm relies on Zephyr SDK for the use of C preprocessor (devicetree) and objcopy
find_package(Zephyr-sdk 0.15 REQUIRED)
message(STATUS "Found Zephyr SDK at ${ZEPHYR_SDK_INSTALL_DIR}")

set(TOOLCHAIN_HOME ${ICCARM_TOOLCHAIN_PATH})

# Handling to be improved in Zephyr SDK, to avoid overriding ZEPHYR_TOOLCHAIN_VARIANT by
# find_package(Zephyr-sdk) if it's already set
set(ZEPHYR_TOOLCHAIN_VARIANT iccarm)

set(COMPILER iccarm)
set(LINKER ilinkarm)
set(BINTOOLS iccarm)

set(SYSROOT_TARGET arm)

set(CROSS_COMPILE ${TOOLCHAIN_HOME}/bin/)

set(TOOLCHAIN_HAS_NEWLIB OFF CACHE BOOL "True if toolchain supports NewLib")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CONFIG_SEMIHOST y CACHE BOOL "Enable semihosting")
  set(CONFIG_SEMIHOST_CONSOLE y CACHE BOOL "Enable semihosting console")
  set(CONFIG_UART_CONSOLE n CACHE BOOL "Disable uart console")
  set(CONFIG_SERIAL n CACHE BOOL "Disable serial")
endif()
