# SPDX-License-Identifier: Apache-2.0
#set(CMAKE_REQUIRED_QUIET 0)
#set_property(TARGET linker PROPERTY devices_start_symbol "__device_start")
set_property(TARGET linker PROPERTY devices_start_symbol "device$$Base")
find_program(CMAKE_LINKER
  NAMES ${CROSS_COMPILE}ilinkarm
  PATHS ${TOOLCHAIN_HOME}
  PATH_SUFFIXES bin
  NO_DEFAULT_PATH
)

add_custom_target(ilinkarm)

function(toolchain_ld_force_undefined_symbols)
#  foreach(symbol ${ARGN})
#    zephyr_link_libraries(--place_holder=${symbol})
#  endforeach()
endfunction()

# NOTE: ${linker_script_gen} will be produced at build-time; not at configure-time
macro(configure_linker_script linker_script_gen linker_pass_define)
  set(extra_dependencies ${ARGN})
  # set(STEERING_FILE)
  # set(STEERING_C)
  # set(STEERING_FILE_ARG)
  # set(STEERING_C_ARG)
  set(linker_pass_define_list ${linker_pass_define})

  # if("LINKER_ZEPHYR_FINAL" IN_LIST linker_pass_define_list)
  #   set(STEERING_FILE ${CMAKE_CURRENT_BINARY_DIR}/ilinkarm_symbol_steering.steer)
  #   set(STEERING_C ${CMAKE_CURRENT_BINARY_DIR}/ilinkarm_symbol_steering.c)
  #   set(STEERING_FILE_ARG "-DSTEERING_FILE=${STEERING_FILE}")
  #   set(STEERING_C_ARG "-DSTEERING_C=${STEERING_C}")
  # endif()

  add_custom_command(
    OUTPUT ${linker_script_gen}
	   # ${STEERING_FILE}
	   # ${STEERING_C}
    DEPENDS
      ${extra_dependencies}
    COMMAND ${CMAKE_COMMAND}
      -DPASS="${linker_pass_define}"
      -DMEMORY_REGIONS="$<TARGET_PROPERTY:linker,MEMORY_REGIONS>"
      -DGROUPS="$<TARGET_PROPERTY:linker,GROUPS>"
      -DSECTIONS="$<TARGET_PROPERTY:linker,SECTIONS>"
      -DSECTION_SETTINGS="$<TARGET_PROPERTY:linker,SECTION_SETTINGS>"
      -DSYMBOLS="$<TARGET_PROPERTY:linker,SYMBOLS>"
      # ${STEERING_FILE_ARG}
      # ${STEERING_C_ARG}
      -DCONFIG_LINKER_LAST_SECTION_ID=${CONFIG_LINKER_LAST_SECTION_ID}
      -DCONFIG_LINKER_LAST_SECTION_ID_PATTERN=${CONFIG_LINKER_LAST_SECTION_ID_PATTERN}
      -DOUT_FILE=${CMAKE_CURRENT_BINARY_DIR}/${linker_script_gen}
      -P ${ZEPHYR_BASE}/cmake/linker/ilinkarm/scatter_script.cmake
  )

  # if("LINKER_ZEPHYR_FINAL" IN_LIST linker_pass_define_list)
  #   add_library(ilinkarm_steering OBJECT ${STEERING_C})
  #   target_link_libraries(ilinkarm_steering PRIVATE zephyr_interface)
  # endif()
endmacro()

function(toolchain_ld_link_elf)
  cmake_parse_arguments(
    TOOLCHAIN_LD_LINK_ELF                                     # prefix of output variables
    ""                                                        # list of names of the boolean arguments
    "TARGET_ELF;OUTPUT_MAP;LINKER_SCRIPT"                     # list of names of scalar arguments
    "LIBRARIES_PRE_SCRIPT;LIBRARIES_POST_SCRIPT;DEPENDENCIES" # list of names of list arguments
    ${ARGN}                                                   # input args to parse
  )

  #message("The libs in the ZEPHYR_LIBS_PROPERTY")
  foreach(lib ${ZEPHYR_LIBS_PROPERTY})
  #  message("${lib}")
    # if(NOT ${lib} STREQUAL arch__arm__core__cortex_m)
      list(APPEND ZEPHYR_LIBS_OBJECTS $<TARGET_OBJECTS:${lib}>)
      list(APPEND ZEPHYR_LIBS_OBJECTS $<TARGET_PROPERTY:${lib},LINK_LIBRARIES>)
    # endif()
  endforeach()
  #message("")

  set(ILINK_SEMIHOSTING)
  set(ILINK_BUFFERED_WRITE)
  if(${CONFIG_IAR_SEMIHOSTING})
    set(ILINK_SEMIHOSTING "--semihosting")
  endif()
  if(${CONFIG_IAR_BUFFERED_WRITE})
    set(ILINK_BUFFERED_WRITE "--redirect __write=__write_buffered")
  endif()

  target_link_libraries(
    ${TOOLCHAIN_LD_LINK_ELF_TARGET_ELF}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_PRE_SCRIPT}
    --config=${TOOLCHAIN_LD_LINK_ELF_LINKER_SCRIPT}
    ${TOOLCHAIN_LD_LINK_ELF_LIBRARIES_POST_SCRIPT}
    --map=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}
    --log_file=${TOOLCHAIN_LD_LINK_ELF_OUTPUT_MAP}.log

    ${ZEPHYR_LIBS_OBJECTS}
    kernel
    $<TARGET_OBJECTS:${OFFSETS_LIB}>
    --entry=$<TARGET_PROPERTY:linker,ENTRY>

    ${ILINK_SEMIHOSTING}
    ${ILINK_BUFFERED_WRITE}
    # Do not remove symbols
    #--no_remove
    # $<TARGET_OBJECTS:ilinkarm_steering>
    # -f ${CMAKE_CURRENT_BINARY_DIR}/ilinkarm_symbol_steering.steer

    ${TOOLCHAIN_LIBS_OBJECTS}

    ${TOOLCHAIN_LD_LINK_ELF_DEPENDENCIES}
  )
endfunction(toolchain_ld_link_elf)

include(${ZEPHYR_BASE}/cmake/linker/ld/target_relocation.cmake)
include(${ZEPHYR_BASE}/cmake/linker/ld/target_configure.cmake)
