#Keep in synch with include/zephyr/linker/kobject-priv-stacks.ld
if(CONFIG_USERSPACE)
  if(CONFIG_GEN_PRIV_STACKS)
  
    zephyr_linker_section(NAME .priv_stacks_noinit GROUP NOINIT_REGION NOINPUT NOINIT)

    zephyr_linker_section_configure(
      SECTION .priv_stacks_noinit
      SYMBOLS z_priv_stacks_ram_start
    )

    #/* During LINKER_KOBJECT_PREBUILT and LINKER_ZEPHYR_PREBUILT,
	  #* space needs to be reserved for the rodata that will be
	  #* produced by gperf during the final stages of linking.
	  #* The alignment and size are produced by
	  #* scripts/build/gen_kobject_placeholders.py. These are here
	  #* so the addresses to kobjects would remain the same
	  #* during the final stages of linking (LINKER_ZEPHYR_FINAL).
	  #*/
    #For prebuilt we need a way to set the size of some space to 
    # KOBJECT_PRIV_STACKS_SZ from linker-kobject-prebuilt-priv-stacks.h
    # For now, this is probably ok since noinit sits after bss and so "should not" affect any of the addresses...
    zephyr_linker_section_configure(
      SECTION .priv_stacks_noinit
      ALIGN 4 #KOBJECT_PRIV_STACKS_ALIGN
      INPUT ".priv_stacks.noinit"
      KEEP
      PASS NOT LINKER_ZEPHYR_FINAL
    )

    zephyr_linker_section_configure(
      SECTION .priv_stacks_noinit
      ALIGN 4 #KOBJECT_PRIV_STACKS_ALIGN
      INPUT ".priv_stacks.noinit"
      KEEP
      PASS LINKER_ZEPHYR_FINAL
    )

    zephyr_linker_section_configure(
      SECTION .priv_stacks_noinit
      SYMBOLS z_priv_stacks_ram_end
    )

    if(KOBJECT_PRIV_STACKS_ALIGN)
      zephyr_linker_symbol(
        SYMBOL z_priv_stacks_ram_used
        EXPR "(@z_priv_stacks_ram_end@ - @z_priv_stacks_ram_start@)"
        PASS LINKER_ZEPHYR_FINAL
      )
    endif()
  endif()
endif()