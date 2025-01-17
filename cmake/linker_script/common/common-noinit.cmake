zephyr_linker_section(NAME .noinit GROUP NOINIT_REGION TYPE NOLOAD NOINIT)

zephyr_linker_section_configure(
  SECTION .noinit
  INPUT ".user_stacks*"
  SYMBOLS z_user_stacks_start z_user_stacks_end)

  ##include <snippets-noinit.ld>
include(${COMMON_ZEPHYR_LINKER_DIR}/kobject-priv-stacks.cmake)