#From kobject-rom.ld
# /* During LINKER_KOBJECT_PREBUILT and LINKER_ZEPHYR_PREBUILT,
#	 * space needs to be reserved for the rodata that will be
#	 * produced by gperf during the final stages of linking.
#	 * The alignment and size are produced by
#	 * scripts/build/gen_kobject_placeholders.py. These are here
#	 * so the addresses to kobjects would remain the same
#	 * during the final stages of linking (LINKER_ZEPHYR_FINAL).
#	 */

if(CONFIG_USERSPACE)
  # By the magic of MIN_SIZE the space will be there, We dont get any symbols though. but we dont seem to need them? 
  zephyr_linker_section_configure(SECTION .rodata INPUT ".kobject_data.rodata*" MIN_SIZE KOBJECT_RODATA_SZ ALIGN KOBJECT_RODATA_ALIGN)
endif()
