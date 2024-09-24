# SPDX-License-Identifer: Apache-2.0

#set(CMAKE_REQUIRED_QUIET 0)

# Avoids running the linker during try_compile()
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

find_program(CMAKE_C_COMPILER
  NAMES iccarm
  PATHS ${TOOLCHAIN_HOME}
  PATH_SUFFIXES bin
  NO_DEFAULT_PATH
  REQUIRED )

find_program(CMAKE_CXX_COMPILER
  NAMES iccarm
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

find_program(CMAKE_ASM_COMPILER
  arm-zephyr-eabi-gcc
  PATHS ${ZEPHYR_SDK_INSTALL_DIR}/arm-zephyr-eabi/bin
  NO_DEFAULT_PATH )

set(ICC_BASE ${ZEPHYR_BASE}/cmake/compiler/iccarm)

# Used for settings correct cpu/fpu option for gnu assembler
include(${ZEPHYR_BASE}/cmake/gcc-m-cpu.cmake)
include(${ZEPHYR_BASE}/cmake/gcc-m-fpu.cmake)

# Map KConfig option to icc cpu/fpu
include(${ICC_BASE}/iccarm-cpu.cmake)
include(${ICC_BASE}/iccarm-fpu.cmake)

# Minimal C compiler flags
list(APPEND TOOLCHAIN_C_FLAGS
  --endian=little
  --macro_positions_in_diagnostics
  --no_wrap_diagnostics
  --cpu=${ICCARM_CPU}
  "SHELL: --preinclude"
  "${ZEPHYR_BASE}/include/zephyr/toolchain/iccarm_missing_defs.h"
  -e
  -eptrarith
  -ereturn_void_expression
  -egcc_inline_asm_breaks
  -egcc_escape_character
  --zephyr
  --vla
  # Suppress diags
  --diag_suppress=Pe257  # xxx requires an initializer
  --diag_suppress=Pe054  # too few arguments in invocation of macro
  --diag_suppress=Pa082  # undefined behavior: the order of volatile accesses is undefined
  --diag_suppress=Pa084  # pointless integer comparison, the result is always false
#  --diag_suppress=Pa167  # Warning for unknown attribute
  --diag_error=Pe191

  --diag_suppress=Pe068  # integer conversion resulted in a change of sign
  --diag_suppress=Pe111  # statement is unreachable
  --diag_suppress=Pe144  # a value of type "void *" cannot be used to initialize...
  --diag_suppress=Pe167  # argument of type "onoff_notify_fn" is incompatible with...
  --diag_suppress=Pe186  # pointless comparison of unsigned integer with zero
  --diag_suppress=Pe188  # enumerated type mixed with another type
  --diag_suppress=Pe223  # function "xxx" declared implicitly
  --diag_suppress=Pe381  # extra ";" ignored
  --diag_suppress=Pe546  # transfer of control bypasses initialization
  --diag_suppress=Pe550  # variable "res" was set but never used
  --diag_suppress=Pe606  # this pragma must immediately precede a declaration
  --diag_suppress=Pe767  # conversion from pointer to smaller integer
  #--diag_suppress=Pe1305 # function declared with "noreturn" does return
  --diag_suppress=Pe1675 # unrecognized GCC pragma
  --diag_suppress=Pe1717 # array of elements containing a flexible array member is nonstandard


  --diag_suppress=Pe120  # return value type ("xxx") does not match the function type...
  --diag_suppress=Pe128  # loop is not reachable
  --diag_suppress=Pe118  # a void function may not return a value
  --diag_suppress=Pe513  # a value of type "void *" cannot be assigned to an entity of type "int (*)(int)"
  --diag_suppress=Pe042  # operand types are incompatible ("void *" and "void (*)(void *, void *, void *)")
  --diag_suppress=Pe1143 # arithmetic on pointer to void or function type
  --diag_suppress=Be006  # possible conflict for segment/section "xxx"
  --diag_suppress=Ta184  # Using zero sized arrays except for as last member of a struct is discouraged and dereferencing elements in such an array has undefined behavior
  #--diag_suppress=Pa181  # incompatible redefinition of macro
  --diag_suppress=Pe1153  # declaration does not match its alias variable "xxx"
  --diag_suppress=Pe191  # type qualifier is meaningless on cast type
)

if(CONFIG_ENFORCE_ZEPHYR_STDINT)
  list(APPEND TOOLCHAIN_C_FLAGS
    "SHELL: --preinclude ${ZEPHYR_BASE}/include/zephyr/toolchain/zephyr_stdint.h"
  )
endif()

# Place test command line options here so not to pollute the necessary
list(APPEND TOOLCHAIN_C_FLAGS
  #--enable_gnu_compatibility

  # Note that cmake de-duplication removes a second '.' argument, so for
  # options that uses '.' as destination we must wrap them with "SHELL:<command line option>"
  #"SHELL:-lCH  ."
  #"SHELL:--preprocess=c ."

#  -r
#  --separate_cluster_for_initialized_variables
#  --warnings_are_errors
#  --trace BE_CODEGEN
)

# Minimal ASM compiler flags
list(APPEND TOOLCHAIN_ASM_FLAGS
  -mcpu=${GCC_M_CPU}
  -mabi=aapcs
  )

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  # GCC defaults to Dwarf 5 output
  list(APPEND TOOLCHAIN_ASM_FLAGS -gdwarf-4)
endif()

if (DEFINED CONFIG_ARM_SECURE_FIRMWARE)
  list(APPEND TOOLCHAIN_C_FLAGS --cmse)
  list(APPEND TOOLCHAIN_ASM_FLAGS -mcmse)
endif()

# 64-bit
if(CONFIG_ARM64)
  list(APPEND TOOLCHAIN_C_FLAGS --abi=lp64)
  list(APPEND TOOLCHAIN_LD_FLAGS --abi=lp64)
# 32-bit
else()
  list(APPEND TOOLCHAIN_C_FLAGS --aeabi)
  if(CONFIG_COMPILER_ISA_THUMB2)
    list(APPEND TOOLCHAIN_C_FLAGS --thumb)
    list(APPEND TOOLCHAIN_ASM_FLAGS -mthumb)
  endif()

  if(CONFIG_FPU)
    list(APPEND TOOLCHAIN_C_FLAGS --fpu=${ICCARM_FPU})
    list(APPEND TOOLCHAIN_ASM_FLAGS -mfpu=${GCC_M_FPU})
  endif()
endif()

if(CONFIG_ICCARM_LIBC)
  # Zephyr requires AEABI portability to ensure correct functioning of the C
  # library, for example error numbers, errno.h.
  list(APPEND TOOLCHAIN_C_FLAGS -D__AEABI_PORTABILITY_LEVEL=1)
endif()

if(CONFIG_REQUIRES_FULL_LIBC)
  list(APPEND TOOLCHAIN_C_FLAGS --dlib_config full)
endif()

set(CONFIG_COMPILER_FREESTANDING 1)
set(CONFIG_CBPRINTF_LIBC_SUBSTS 1)

