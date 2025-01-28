# SPDX-License-Identifier: Apache-2.0

#set(CMAKE_REQUIRED_QUIET 0)

# Avoids running the linker during try_compile()
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(NO_BUILD_TYPE_WARNING 1)
set(CMAKE_NOT_USING_CONFIG_FLAGS 1)

find_program(CMAKE_C_COMPILER
  NAMES ${IAR_COMPILER}
  PATHS ${TOOLCHAIN_HOME}
  PATH_SUFFIXES bin
  NO_DEFAULT_PATH
  REQUIRED )

message(STATUS "Found C Compiler ${CMAKE_C_COMPILER}")

find_program(CMAKE_CXX_COMPILER
  NAMES ${IAR_COMPILER}
  PATHS ${TOOLCHAIN_HOME}
  PATH_SUFFIXES bin
  NO_DEFAULT_PATH
  REQUIRED )

find_program(CMAKE_AR
  NAMES iarchive
  PATHS ${TOOLCHAIN_HOME}
  PATH_SUFFIXES bin
  NO_DEFAULT_PATH
  REQUIRED )

set(CMAKE_ASM_COMPILER)
if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  find_program(CMAKE_ASM_COMPILER
    arm-zephyr-eabi-gcc
    PATHS ${ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi/bin
    NO_DEFAULT_PATH )
else()
  find_program(CMAKE_ASM_COMPILER
    riscv64-zephyr-elf-gcc
    PATHS ${ZEPHYR_SDK_INSTALL_DIR}/riscv64-zephyr-elf/bin
    NO_DEFAULT_PATH )
endif()

message(STATUS "Found assembler ${CMAKE_ASM_COMPILER}")

set(ICC_BASE ${ZEPHYR_BASE}/cmake/compiler/iar)


if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  # Used for settings correct cpu/fpu option for gnu assembler
  include(${ZEPHYR_BASE}/cmake/gcc-m-cpu.cmake)
  include(${ZEPHYR_BASE}/cmake/gcc-m-fpu.cmake)

  # Map KConfig option to icc cpu/fpu
  include(${ICC_BASE}/iccarm-cpu.cmake)
  include(${ICC_BASE}/iccarm-fpu.cmake)
endif()
if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccriscv")
  # Used for settings correct cpu/fpu option for gnu assembler
  include(${ZEPHYR_BASE}/cmake/gcc-m-cpu.cmake)
  include(${ZEPHYR_BASE}/cmake/gcc-m-fpu.cmake)

  # Map KConfig option to icc cpu/fpu
  include(${ICC_BASE}/iccriscv-cpu.cmake)
endif()

set(IAR_COMMON_FLAGS)
# Minimal C compiler flags

list(APPEND TOOLCHAIN_C_FLAGS
  --vla
)
list(APPEND IAR_COMMON_FLAGS
  "SHELL: --preinclude"
  "${ZEPHYR_BASE}/include/zephyr/toolchain/iar/iar_missing_defs.h"
  # Enable both IAR and GNU extensions
  --language extended,gnu
  --do_explicit_init_in_named_sections
  --macro_positions_in_diagnostics
  --no_wrap_diagnostics
)

if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  list(APPEND IAR_COMMON_FLAGS
    --endian=little
    --cpu=${ICCARM_CPU}
    --no_var_align
    --no_const_align

    -DRTT_USE_ASM=0       #WA for VAAK-232

    --diag_suppress=Ta184  # Using zero sized arrays except for as last member of a struct is discouraged and dereferencing elements in such an array has undefined behavior
  )
else()
  list(APPEND IAR_COMMON_FLAGS

  )
endif()

if(CONFIG_ENFORCE_ZEPHYR_STDINT)
  list(APPEND IAR_COMMON_FLAGS
    "SHELL: --preinclude ${ZEPHYR_BASE}/include/zephyr/toolchain/zephyr_stdint.h"
  )
endif()

# Place test command line options here so not to pollute the necessary
list(APPEND IAR_COMMON_FLAGS
  #--enable_gnu_compatibility

  # Note that cmake de-duplication removes a second '.' argument, so for
  # options that uses '.' as destination we must wrap them with "SHELL:<command line option>"
  #"SHELL:-lCH  ."
  #"SHELL:--preprocess=c ."
  #--no_cross_jump

#  -r
#  --separate_cluster_for_initialized_variables
# --warnings_are_errors
#  --trace BE_CODEGEN
)

# Minimal ASM compiler flags
if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  list(APPEND TOOLCHAIN_ASM_FLAGS
    -mcpu=${GCC_M_CPU}
    -mabi=aapcs
    -DRTT_USE_ASM=0       #WA for VAAK-232
    )
endif()

if(CONFIG_DEBUG)
  # GCC defaults to Dwarf 5 output
  list(APPEND TOOLCHAIN_ASM_FLAGS -gdwarf-4)
endif()

if (DEFINED CONFIG_ARM_SECURE_FIRMWARE)
  list(APPEND IAR_COMMON_FLAGS --cmse)
  list(APPEND TOOLCHAIN_ASM_FLAGS -mcmse)
endif()

# 64-bit
if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  if(CONFIG_ARM64)
    list(APPEND IAR_COMMON_FLAGS --abi=lp64)
    list(APPEND TOOLCHAIN_LD_FLAGS --abi=lp64)
  # 32-bit
  else()
    list(APPEND IAR_COMMON_FLAGS --aeabi)
    if(CONFIG_COMPILER_ISA_THUMB2)
      list(APPEND IAR_COMMON_FLAGS --thumb)
      list(APPEND TOOLCHAIN_ASM_FLAGS -mthumb)
    endif()

    if(CONFIG_FPU)
      list(APPEND IAR_COMMON_FLAGS --fpu=${ICCARM_FPU})
      list(APPEND TOOLCHAIN_ASM_FLAGS -mfpu=${GCC_M_FPU})
    endif()
  endif()
endif()

if ("${IAR_TOOLCHAIN_VARIANT}" STREQUAL "iccarm")
  if(CONFIG_IAR_LIBC)
    # Zephyr requires AEABI portability to ensure correct functioning of the C
    # library, for example error numbers, errno.h.
    list(APPEND IAR_COMMON_FLAGS -D__AEABI_PORTABILITY_LEVEL=1)
  endif()
endif()

if(CONFIG_IAR_LIBCPP)
  message(STATUS "IAR C++ library used")
endif()

if(CONFIG_IAR_LIBC)
  message(STATUS "IAR C library used")
  # Zephyr uses the type FILE for normal LIBC while IAR
  # only has it for full LIBC support, so always choose
  # full libc when using IAR C libraries.
  list(APPEND TOOLCHAIN_C_FLAGS --dlib_config full)
endif()

list(APPEND TOOLCHAIN_C_FLAGS ${IAR_COMMON_FLAGS})
list(APPEND TOOLCHAIN_CXX_FLAGS ${IAR_COMMON_FLAGS})
