# Compiler options for the IAR C/C++ Compiler for Arm


#####################################################
# This section covers flags related to optimization #
#####################################################
set_compiler_property(PROPERTY no_optimization -On)

set_compiler_property(PROPERTY optimization_debug -Ol)

set_compiler_property(PROPERTY optimization_speed -Ohs)

set_compiler_property(PROPERTY optimization_size -Ohz)

#######################################################
# This section covers flags related to warning levels #
#######################################################

# Property for standard warning base in Zephyr, this will always be set when compiling.
set_compiler_property(PROPERTY warning_base)

# GCC options for warning levels 1, 2, 3, when using `-DW=[1|2|3]`
# Property for warning levels 1, 2, 3 in Zephyr when using `-DW=[1|2|3]`
set_compiler_property(PROPERTY warning_dw_1)

set_compiler_property(PROPERTY warning_dw_2)

set_compiler_property(PROPERTY warning_dw_3)

# Extended warning set supported by the compiler
set_compiler_property(PROPERTY warning_extended)

# Compiler property that will issue error if a declaration does not specify a type
set_compiler_property(PROPERTY warning_error_implicit_int)

# Compiler flags to use when compiling according to MISRA
set_compiler_property(PROPERTY warning_error_misra_sane)

set_property(TARGET compiler PROPERTY warnings_as_errors  --warnings_are_errors)

###########################################################################
# This section covers flags related to C or C++ standards / standard libs #
###########################################################################

# Compiler flags for C standard. The specific standard must be appended by user.
# For example, gcc specifies this as: set_compiler_property(PROPERTY cstd -std=)
# TC-WG: the `cstd99` is used regardless of this flag being useful for iccarm
# This flag will make it a symbol. Works for C,CXX,ASM
# Since ICCARM does not use C standard flags, we just make them a defined symbol
# instead
set_compiler_property(PROPERTY cstd -D__IAR_CSTD_)

# Compiler flags for disabling C standard include and instead specify include
# dirs in nostdinc_include to use.
set_compiler_property(PROPERTY nostdinc)
set_compiler_property(PROPERTY nostdinc_include)

# Compiler flags for disabling C++ standard include.
set_compiler_property(TARGET compiler-cpp PROPERTY nostdincxx)

# Required C++ flags when compiling C++ code
set_property(TARGET compiler-cpp PROPERTY required --c++)

# Compiler flags to use for specific C++ dialects
set_property(TARGET compiler-cpp PROPERTY dialect_cpp98)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp11)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp14)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp17 --libc++)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp2a --libc++)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp20 --libc++)
set_property(TARGET compiler-cpp PROPERTY dialect_cpp2b --libc++)

# Flag for disabling strict aliasing rule in C and C++
set_compiler_property(PROPERTY no_strict_aliasing)

# Flag for disabling exceptions in C++
set_property(TARGET compiler-cpp PROPERTY no_exceptions --no_exceptions)

# Flag for disabling rtti in C++
set_property(TARGET compiler-cpp PROPERTY no_rtti --no_rtti)


###################################################
# This section covers all remaining C / C++ flags #
###################################################

# Flags for coverage generation
set_compiler_property(PROPERTY coverage)

# Security canaries flags.
set_compiler_property(PROPERTY security_canaries --stack_protection)

set_compiler_property(PROPERTY security_fortify)

# Flag for a hosted (no-freestanding) application
set_compiler_property(PROPERTY hosted)

# gcc flag for a freestanding application
set_compiler_property(PROPERTY freestanding)

# Flag to include debugging symbol in compilation
set_property(TARGET compiler PROPERTY debug --debug)
set_property(TARGET compiler-cpp PROPERTY debug --debug)
set_property(TARGET asm PROPERTY debug -gdwarf-4)

set_compiler_property(PROPERTY no_common)

# Flags for imacros. The specific header must be appended by user.
set_property(TARGET compiler PROPERTY imacros --preinclude)
set_property(TARGET compiler-cpp PROPERTY imacros --preinclude)
set_property(TARGET asm PROPERTY imacros -imacros)

# Compiler flag for turning off thread-safe initialization of local statics
set_property(TARGET compiler-cpp PROPERTY no_threadsafe_statics)

# Required ASM flags when compiling
set_property(TARGET asm PROPERTY required)

# Compiler flag for disabling pointer arithmetic warnings
set_compiler_property(PROPERTY warning_no_pointer_arithmetic)

# Compiler flags for disabling position independent code / executable
set_compiler_property(PROPERTY no_position_independent)

set_property(TARGET compiler PROPERTY iar_do_not_use --love)
