cmake_minimum_required(VERSION 3.17)

set(SORT_TYPE_NAME Lexical)

# This function post process the region for easier use.
#
# Tasks:
# - Symbol translation using a steering file is configured.
function(process_region)
  cmake_parse_arguments(REGION "" "OBJECT" "" ${ARGN})

  process_region_common(${ARGN})

  get_property(empty GLOBAL PROPERTY ${REGION_OBJECT}_EMPTY)
  if(NOT empty)
    # For scatter files we move any system symbols into first non-empty load section.
    get_parent(OBJECT ${REGION_OBJECT} PARENT parent TYPE SYSTEM)
    get_property(symbols GLOBAL PROPERTY ${parent}_SYMBOLS)
    set_property(GLOBAL APPEND PROPERTY ${REGION_OBJECT}_SYMBOLS ${symbols})
    set_property(GLOBAL PROPERTY ${parent}_SYMBOLS)
  endif()

  get_property(sections GLOBAL PROPERTY ${REGION_OBJECT}_SECTION_LIST_ORDERED)
  foreach(section ${sections})

    get_property(name       GLOBAL PROPERTY ${section}_NAME)
    get_property(name_clean GLOBAL PROPERTY ${section}_NAME_CLEAN)
    get_property(noinput    GLOBAL PROPERTY ${section}_NOINPUT)
    get_property(type       GLOBAL PROPERTY ${section}_TYPE)
    get_property(nosymbols  GLOBAL PROPERTY ${section}_NOSYMBOLS)

    # message("process_region name_clean=${name_clean}")

    if(NOT nosymbols)
      if(${name} STREQUAL .ramfunc)
        create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name_clean}_load_start
          EXPR "(@.textrw_init$$Base@)"
          )
      else()
        create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name_clean}_load_start
          EXPR "(@Load$$${name_clean}$$Base@)"
          )
      endif()
    endif()

    get_property(indicies GLOBAL PROPERTY ${section}_SETTINGS_INDICIES)
    list(LENGTH indicies length)
    foreach(idx ${indicies})
      set(steering_postfixes Base Limit)
      get_property(symbols GLOBAL PROPERTY ${section}_SETTING_${idx}_SYMBOLS)
      get_property(sort    GLOBAL PROPERTY ${section}_SETTING_${idx}_SORT)
      get_property(offset  GLOBAL PROPERTY ${section}_SETTING_${idx}_OFFSET)
      if(DEFINED offset AND NOT offset EQUAL 0 )
        # Same behavior as in section_to_string
      elseif(DEFINED offset AND offset STREQUAL 0 )
        # Same behavior as in section_to_string
      elseif(sort)
        # Treated by labels in the icf.
      elseif(DEFINED symbols AND ${length} EQUAL 1 AND noinput)
        # set(steering_postfixes Base Limit)
        # foreach(symbol ${symbols})
        #   list(POP_FRONT steering_postfixes postfix)
        #   set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_C
        #     "${name_clean}$$${postfix}"
        #   )
        #   set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
        #     "--redirect ${symbol}=${name_clean}$$${postfix}\n"
        #   )
        # endforeach()
      endif()
    endforeach()

    if("${type}" STREQUAL BSS)
      set(ZI "$$ZI")
    endif()

    # Symbols translation here.

    get_property(symbol_val GLOBAL PROPERTY SYMBOL_TABLE___${name_clean}_end)

    if("${symbol_val}" STREQUAL "${name_clean}")
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name_clean}_size
        EXPR "(@${name_clean}${ZI}$$Length@)"
        )
    else()
      # These seem to be thing that can't be transformed to $$Length
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name_clean}_size
        EXPR "(@${symbol_val}${ZI}$$Limit@ - @${name_clean}${ZI}$$Base@)"
        )

    endif()
    set(ZI)

    if(${name_clean} STREQUAL last_ram_section)
      # A trick to add the symbol for the nxp devices
      # _flash_used = LOADADDR(.last_section) + SIZEOF(.last_section) - __rom_region_start;
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL _flash_used
        EXPR "(@Load$$last_section$$Base@ + @last_section$$Length@ - @__rom_region_start@)"
        )
    endif()

    if(${name_clean} STREQUAL rom_start)
      # The below two symbols is meant to make aliases to the _vector_table symbol.
      list(GET symbols 0 symbol_start)
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __Vectors
        EXPR "(@${symbol_start}$$Base@)"
        )
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __vector_table
        EXPR "(@${symbol_start}$$Base@)"
        )
    endif()

  endforeach()

  get_property(groups GLOBAL PROPERTY ${REGION_OBJECT}_GROUP_LIST_ORDERED)
  foreach(group ${groups})
    get_property(name GLOBAL PROPERTY ${group}_NAME)
    string(TOLOWER ${name} name)

    get_objects(LIST sections OBJECT ${group} TYPE SECTION)
    list(GET sections 0 section)
    get_property(first_section_name GLOBAL PROPERTY ${section}_NAME_CLEAN)
    list(POP_BACK sections section)
    get_property(last_section_name GLOBAL PROPERTY ${section}_NAME_CLEAN)

    create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name}_load_start
      EXPR "(@Load$$${first_section_name}$$Base@)"
      )

    create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name}_start
      EXPR "(@${first_section_name}$$Base@)"
      )
    create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name}_end
      EXPR "(@${last_section_name}$$Limit@)"
      )
    create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name}_size
      EXPR "(@${last_section_name}$$Limit@ - @${first_section_name}$$Base@)"
      )

  endforeach()

  get_property(symbols GLOBAL PROPERTY ${REGION_OBJECT}_SYMBOLS)
  foreach(symbol ${symbols})
    get_property(name GLOBAL PROPERTY ${symbol}_NAME)
    get_property(expr GLOBAL PROPERTY ${symbol}_EXPR)
    if(NOT DEFINED expr)
      create_symbol(OBJECT ${REGION_OBJECT} SYMBOL __${name}_size
        EXPR "(@${name}$$Base@)"
        )
    endif()
  endforeach()

  # This is only a trick to get the memories
  set(groups)
  get_objects(LIST groups OBJECT ${REGION_OBJECT} TYPE GROUP)
  foreach(group ${groups})
    get_property(group_type  GLOBAL PROPERTY ${group}_OBJ_TYPE)
    get_property(parent      GLOBAL PROPERTY ${group}_PARENT)
    get_property(parent_type GLOBAL PROPERTY ${parent}_OBJ_TYPE)

    if(${group_type} STREQUAL GROUP)
      get_property(group_name GLOBAL PROPERTY ${group}_NAME)
      get_property(group_lma  GLOBAL PROPERTY ${group}_LMA)
      if(${group_name} STREQUAL ROM_REGION)
        # message("group_name ${group_name}")
        # message("group_lma ${group_lma}")
        set_property(GLOBAL PROPERTY ILINK_ROM_REGION_NAME ${group_lma})
      endif()
    endif()

    if(${parent_type} STREQUAL GROUP)
      get_property(vma GLOBAL PROPERTY ${parent}_VMA)
      get_property(lma GLOBAL PROPERTY ${parent}_LMA)

      set_property(GLOBAL PROPERTY ${group}_VMA ${vma})
      set_property(GLOBAL PROPERTY ${group}_LMA ${lma})
    endif()
  endforeach()

endfunction()

#
# String functions - start
#

function(system_to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  get_property(name    GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
  get_property(regions GLOBAL PROPERTY ${STRING_OBJECT}_REGIONS)
  get_property(format  GLOBAL PROPERTY ${STRING_OBJECT}_FORMAT)

  # Ilink specials
  # set(${STRING_STRING} "build for rom;\n")
  set(${STRING_STRING} "build for ram;\n")
  if("${format}" MATCHES "aarch64")
    set(${STRING_STRING} "${${STRING_STRING}}define memory mem with size = 16E;\n")
  else()
    set(${STRING_STRING} "${${STRING_STRING}}define memory mem with size = 4G;\n")
  endif()

  foreach(region ${regions})
    get_property(name    GLOBAL PROPERTY ${region}_NAME)
    get_property(address GLOBAL PROPERTY ${region}_ADDRESS)
    get_property(flags   GLOBAL PROPERTY ${region}_FLAGS)
    get_property(size    GLOBAL PROPERTY ${region}_SIZE)

    # message("region name ${name}")
    # message("region address ${address}")
    # message("region flags ${flags}")
    # message("region size ${size}")

    if(DEFINED flags)
      if(${flags} STREQUAL rx)
        set(flags " rom")
      elseif(${flags} STREQUAL ro)
        set(flags " rom")
      elseif(${flags} STREQUAL wx)
        set(flags " ram")
      elseif(${flags} STREQUAL rw)
        set(flags " ram")
      endif()
    endif()

    if(${name} STREQUAL IDT_LIST)
      # Need to use a untyped region for IDT_LIST
      set(flags "")
    endif()

    if(DEFINED address)
      set(start "${address}")
    endif()

    if(DEFINED size)
      set(size "${size}")
    endif()
    # define rom region FLASH    = mem:[from 0x0 size 0x40000];
    set(memory_region "define${flags} region ${name} = mem:[from ${start} size ${size}];")

    set(${STRING_STRING} "${${STRING_STRING}}${memory_region}\n")
    set(flags)
  endforeach()

  set(${STRING_STRING} "${${STRING_STRING}}\n\n")

  set(${STRING_STRING} "${${STRING_STRING}}\n")
  foreach(region ${regions})
    get_property(empty GLOBAL PROPERTY ${region}_EMPTY)
    if(NOT empty)
      get_property(name    GLOBAL PROPERTY ${region}_NAME)
      set(ILINK_CURRENT_NAME ${name})
      to_string(OBJECT ${region} STRING ${STRING_STRING})
      set(ILINK_CURRENT_NAME)
    endif()
  endforeach()
  set(${STRING_STRING} "${${STRING_STRING}}\n")

  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()

function(group_to_string)
  cmake_parse_arguments(STRING "" "OBJECT;STRING" "" ${ARGN})

  # message("\ngroup_to_string")
  get_property(type GLOBAL PROPERTY ${STRING_OBJECT}_OBJ_TYPE)
  # message("type ${type}")
  if(${type} STREQUAL REGION)
    get_property(name GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
    get_property(address GLOBAL PROPERTY ${STRING_OBJECT}_ADDRESS)
    get_property(size GLOBAL PROPERTY ${STRING_OBJECT}_SIZE)
    # message("name ${name}")
    # message("address ${address}")
    # message("size ${size}")

    get_property(empty GLOBAL PROPERTY ${STRING_OBJECT}_EMPTY)
    if(empty)
      return()
    endif()

  else()
    get_property(else_name GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
    get_property(else_symbol GLOBAL PROPERTY ${STRING_OBJECT}_SYMBOL)
    string(TOLOWER ${else_name} else_name)

    get_objects(LIST sections OBJECT ${STRING_OBJECT} TYPE SECTION)
    list(GET sections 0 section)
    get_property(first_section_name GLOBAL PROPERTY ${section}_NAME)

  endif()

  if(${type} STREQUAL GROUP)
    get_property(group_name GLOBAL PROPERTY ${STRING_OBJECT}_NAME)
    get_property(group_address GLOBAL PROPERTY ${STRING_OBJECT}_ADDRESS)
    get_property(group_vma GLOBAL PROPERTY ${STRING_OBJECT}_VMA)
    get_property(group_lma GLOBAL PROPERTY ${STRING_OBJECT}_LMA)
    # message("group_name ${group_name}")
    # message("group_address ${group_address}")
    # message("group_vma ${group_vma}")
    # message("group_lma ${group_lma}")
  endif()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS_FIXED)
  # message("\ngroup: fixed sections ${sections}")
  foreach(section ${sections})

    # message("\ngroup: fixed section ${section}")
    # message("fixed section: type ${type}")
    # message("ilink_current_name      ${ILINK_CURRENT_NAME}")
    # message("address ${address}")

    to_string(OBJECT ${section} STRING ${STRING_STRING})
    get_property(name       GLOBAL PROPERTY ${section}_NAME)
    # string(REGEX REPLACE "^[\.]" "" name_clean "${name}")
    # string(REPLACE "." "_" name_clean "${name_clean}")
    get_property(name_clean GLOBAL PROPERTY ${section}_NAME_CLEAN)
    set(${STRING_STRING} "${${STRING_STRING}}\"${name}\": place at address mem:${address} { block ${name_clean} };\n")
  endforeach()

  get_property(groups GLOBAL PROPERTY ${STRING_OBJECT}_GROUPS)
  # message("\ngroup: groups ${groups}")
  foreach(group ${groups})

    # message("\ngroup: group(1) ${group}")

    to_string(OBJECT ${group} STRING ${STRING_STRING})
  endforeach()

  get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_SECTIONS)
  # message("\ngroup: sections ${sections}")
  foreach(section ${sections})

    # message("\ngroup: section(1) section=${section}")

    to_string(OBJECT ${section} STRING ${STRING_STRING})

    get_property(name     GLOBAL PROPERTY ${section}_NAME)

    get_property(name_clean GLOBAL PROPERTY ${section}_NAME_CLEAN)

    get_property(parent   GLOBAL PROPERTY ${section}_PARENT)
    # This is only a trick to get the memories
    get_property(parent_type GLOBAL PROPERTY ${parent}_OBJ_TYPE)
    if(${parent_type} STREQUAL GROUP)
      get_property(vma GLOBAL PROPERTY ${parent}_VMA)
      get_property(lma GLOBAL PROPERTY ${parent}_LMA)
    endif()

    # message("parent ${parent}")
    # message("parent_type ${parent_type}")
    # message("vma ${vma}")
    # message("lma ${lma}")

    if(DEFINED vma)
      set(ILINK_CURRENT_NAME ${vma})
    elseif(DEFINED lma)
      set(ILINK_CURRENT_NAME ${lma})
    else()
      # message(FATAL_ERROR "Need either vma or lma")
    endif()

    # message("group: section(1) place in ${ILINK_CURRENT_NAME} { block ${name_clean} };")

    set(${STRING_STRING} "${${STRING_STRING}}\"${name}\": place in ${ILINK_CURRENT_NAME} { block ${name_clean} };\n")

  endforeach()

  get_parent(OBJECT ${STRING_OBJECT} PARENT parent TYPE SYSTEM)
  get_property(regions GLOBAL PROPERTY ${parent}_REGIONS)
  list(REMOVE_ITEM regions ${STRING_OBJECT})

  # message("\ngroup: start regions ${regions}")

  foreach(region ${regions})
    get_property(vma GLOBAL PROPERTY ${region}_NAME)
    get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_SECTIONS_FIXED)
    # message("\ngroup: region ${region}")
    # message("vma ${vma}")
    # message("sections ${sections}")

    foreach(section ${sections})

      # message("group: section(2) vma=${vma} section=${section}")

      to_string(OBJECT ${section} STRING ${STRING_STRING})
    endforeach()

    get_property(groups GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_GROUPS)
    foreach(group ${groups})

      # message("\ngroup: group(2) vma=${vma} group=${group}")

      to_string(OBJECT ${group} STRING ${STRING_STRING})
    endforeach()

    get_property(sections GLOBAL PROPERTY ${STRING_OBJECT}_${vma}_SECTIONS)
    # message("\ngroup: section(3) sections ${sections}")
    foreach(section ${sections})

      # message("\ngroup: section(3) ${vma} ${section}")
      to_string(OBJECT ${section} STRING ${STRING_STRING})
      get_property(name     GLOBAL PROPERTY ${section}_NAME)
      string(REGEX REPLACE "^[\.]" "" name_clean "${name}")
      string(REPLACE "." "_" name_clean "${name_clean}")

      # message("\ngroup: section(3) ${vma} ${section} \"${name}\": place in ${vma} { block ${name_clean} }")
      set(${STRING_STRING} "${${STRING_STRING}}\"${name}\": place in ${vma} { block ${name_clean} };\n")

      # Insert 'do not initialize' here
      get_property(current_sections GLOBAL PROPERTY ILINK_CURRENT_SECTIONS)
      if(${name} STREQUAL .bss)
        if(DEFINED current_sections)
          set(${STRING_STRING} "${${STRING_STRING}}do not initialize\n")
          set(${STRING_STRING} "${${STRING_STRING}}{\n")
          foreach(section ${current_sections})
            set(${STRING_STRING} "${${STRING_STRING}}  ${section},\n")
          endforeach()
          set(${STRING_STRING} "${${STRING_STRING}}};\n")
          set(current_sections)
          set_property(GLOBAL PROPERTY ILINK_CURRENT_SECTIONS)
        endif()
      endif()

      if(${name_clean} STREQUAL last_ram_section)
        get_property(group_name_lma GLOBAL PROPERTY ILINK_ROM_REGION_NAME)
        set(${STRING_STRING} "${${STRING_STRING}}\n")
        if(${CONFIG_LINKER_LAST_SECTION_ID})
          set(${STRING_STRING} "${${STRING_STRING}}define section last_section_id { udata32 ${CONFIG_LINKER_LAST_SECTION_ID_PATTERN}; };\n")
          set(${STRING_STRING} "${${STRING_STRING}}define block last_section with fixed order { section last_section_id };\n")
        else()
          set(${STRING_STRING} "${${STRING_STRING}}define block last_section with fixed order { };\n")
        endif()
        # Not really the right place, we want the last used flash bytes not end of the world!
        # set(${STRING_STRING} "${${STRING_STRING}}\".last_section\": place at end of ${group_name_lma} { block last_section };\n")
        set(${STRING_STRING} "${${STRING_STRING}}\".last_section\": place in ${group_name_lma} { block last_section };\n")
        set(${STRING_STRING} "${${STRING_STRING}}keep { block last_section };\n")
      endif()

    endforeach()
    # message("group: end region ${region}")
  endforeach()
  # message("group: end regions ${regions}")

  get_property(symbols GLOBAL PROPERTY ${STRING_OBJECT}_SYMBOLS)
  # message("\ngroup: symbols ${symbols}")
  set(${STRING_STRING} "${${STRING_STRING}}\n")
  foreach(symbol ${symbols})

    # message("\ngroup: symbol(1) ${symbol}")
    to_string(OBJECT ${symbol} STRING ${STRING_STRING})
  endforeach()

  if(${type} STREQUAL REGION)

    # message("\ngroup: type ${type}")

  endif()
  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()


function(section_to_string)
  cmake_parse_arguments(STRING "" "SECTION;STRING" "" ${ARGN})

  get_property(name     GLOBAL PROPERTY ${STRING_SECTION}_NAME)
  get_property(address  GLOBAL PROPERTY ${STRING_SECTION}_ADDRESS)
  get_property(type     GLOBAL PROPERTY ${STRING_SECTION}_TYPE)
  get_property(align    GLOBAL PROPERTY ${STRING_SECTION}_ALIGN)
  get_property(subalign GLOBAL PROPERTY ${STRING_SECTION}_SUBALIGN)
  get_property(endalign GLOBAL PROPERTY ${STRING_SECTION}_ENDALIGN)
  get_property(vma      GLOBAL PROPERTY ${STRING_SECTION}_VMA)
  get_property(lma      GLOBAL PROPERTY ${STRING_SECTION}_LMA)
  get_property(noinput  GLOBAL PROPERTY ${STRING_SECTION}_NOINPUT)
  get_property(noinit   GLOBAL PROPERTY ${STRING_SECTION}_NOINIT)

  get_property(nosymbols  GLOBAL PROPERTY ${STRING_SECTION}_NOSYMBOLS)
  get_property(start_syms GLOBAL PROPERTY ${STRING_SECTION}_START_SYMBOLS)
  get_property(end_syms   GLOBAL PROPERTY ${STRING_SECTION}_END_SYMBOLS)

  get_property(parent   GLOBAL PROPERTY ${STRING_SECTION}_PARENT)

  get_property(parent_type GLOBAL PROPERTY ${parent}_OBJ_TYPE)
  if(${parent_type} STREQUAL GROUP)
    get_property(group_parent_vma GLOBAL PROPERTY ${parent}_VMA)
    get_property(group_parent_lma GLOBAL PROPERTY ${parent}_LMA)
    if(NOT DEFINED vma)
      get_property(vma GLOBAL PROPERTY ${parent}_VMA)
    endif()
    if(NOT DEFINED lma)
      get_property(lma GLOBAL PROPERTY ${parent}_LMA)
    endif()
  endif()

  set_property(GLOBAL PROPERTY ILINK_CURRENT_SECTIONS)

  # message("\nsection_to_string")
  # message("format ${format}")
  # message("name     ${name}")
  # message("address  ${address}")
  # message("type     ${type}")
  # message("align    ${align}")
  # message("subalign ${subalign}")
  # message("endalign ${endalign}")
  # message("vma      ${vma}")
  # message("lma      ${lma}")
  # message("noinput  ${noinput}")
  # message("noinit   ${noinit}")

  # message("nosymbols   ${nosymbols}")
  # message("start_syms   ${start_syms}")
  # message("end_syms   ${end_syms}")

  # message("parent   ${parent}")
  # message("group_parent_vma      ${group_parent_vma}")
  # message("group_parent_lma      ${group_parent_lma}")

  get_property(indicies GLOBAL PROPERTY ${STRING_SECTION}_SETTINGS_INDICIES)
  # message("indicies ${indicies}")

  string(REGEX REPLACE "^[\.]" "" name_clean "${name}")
  string(REPLACE "." "_" name_clean "${name_clean}")

  foreach(start_symbol ${start_syms})
    set(TEMP "${TEMP}define root section ${start_symbol} { public_notype ${start_symbol}: };\n")
  endforeach()
  foreach(end_symbol ${end_syms})
    set(TEMP "${TEMP}define root section ${end_symbol} { public_notype ${end_symbol}: };\n")
  endforeach()

  if(NOT nosymbols)
    set(TEMP "${TEMP}define root section __${name_clean}_start { public_notype __${name_clean}_start: };\n")
    set(TEMP "${TEMP}define root section __${name_clean}_end   { public_notype __${name_clean}_end:   };\n")
  endif()

  # Add symbol_start and symbol_end
  foreach(idx ${indicies})
    get_property(symbols  GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_SYMBOLS)
    if(DEFINED symbols)
      list(LENGTH symbols symbols_count)
      if(${symbols_count} GREATER 0)
        list(GET symbols 0 symbol_start)
      endif()
      if(${symbols_count} GREATER 1)
        list(GET symbols 1 symbol_end)
      endif()
    endif()

    if(DEFINED symbol_start)
      set(TEMP "${TEMP}define root section ${symbol_start} { public_notype ${symbol_start}: };\n")
    endif()
    if(DEFINED symbol_end)
      set(TEMP "${TEMP}define root section ${symbol_end} { public_notype ${symbol_end}: };\n")
    endif()

    set(symbol_start)
    set(symbol_end)
  endforeach()

  # Add keep to the sections that have 'KEEP:TRUE'
  foreach(idx ${indicies})
    get_property(keep     GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_KEEP)
    get_property(input    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_INPUT)
    foreach(setting ${input})
      if(keep)
        # keep { section .abc* };
        set(TEMP "${TEMP}keep { section ${setting} };\n")
      endif()
    endforeach()
  endforeach()

  set(TEMP "${TEMP}define block ${name_clean} with fixed order")
  if (align)
    set(TEMP "${TEMP}, alignment=${align}")
  else()
    set(TEMP "${TEMP}, alignment=4")
  endif()
  if (endalign)
    set(TEMP "${TEMP}, end alignment=${endalign}")
  endif()

  set(TEMP "${TEMP}\n{")

  foreach(start_symbol ${start_syms})
    set(TEMP "${TEMP}\n  section ${start_symbol},")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${start_symbol}")
  endforeach()

  if(NOT nosymbols)
    set(TEMP "${TEMP}\n  section __${name_clean}_start,")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section __${name_clean}_start")
  endif()

  if(NOT noinput)
    set(TEMP "${TEMP}\n  section ${name},")
    set(TEMP "${TEMP}\n  section ${name}.*,")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${name}")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${name}.*")
  endif()

  list(GET indicies -1 last_index)
  list(LENGTH indicies length)

  get_property(next_indicies GLOBAL PROPERTY ${STRING_SECTION}_SETTINGS_INDICIES)
  list(POP_FRONT next_indicies)

  foreach(idx idx_next IN ZIP_LISTS indicies next_indicies)
    get_property(align    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_ALIGN)
    get_property(any      GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_ANY)
    get_property(first    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_FIRST)
    get_property(keep     GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_KEEP)
    get_property(sort     GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_SORT)
    get_property(flags    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_FLAGS)
    get_property(input    GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_INPUT)
    get_property(symbols  GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx}_SYMBOLS)
    # Get the next offset and use that as this ones size!
    get_property(offset   GLOBAL PROPERTY ${STRING_SECTION}_SETTING_${idx_next}_OFFSET)

    # message("\nidx      ${idx}, ${idx_next}")
    # message("align    ${align}")
    # message("any      ${any}")
    # message("first    ${first}")
    # message("keep     ${keep}")
    # message("sort     ${sort}")
    # message("flags    ${flags}")
    # message("input    ${input}")
    # message("offset   ${offset}")
    # message("last_index ${last_index}")

    if(DEFINED symbols)
      list(LENGTH symbols symbols_count)
      if(${symbols_count} GREATER 0)
        list(GET symbols 0 symbol_start)
        # message("symbol_start: ${symbol_start}")
      endif()
      if(${symbols_count} GREATER 1)
        list(GET symbols 1 symbol_end)
        # message("symbol_end:   ${symbol_end}")
      endif()
    endif()

    if(DEFINED symbol_start)
      set(TEMP "${TEMP}\n  section ${symbol_start},")
      set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${symbol_start}")
    endif()

    # block init_100 with alphabetical order { section .z_init_EARLY?_}
    set(TEMP "${TEMP}\n  block ${name_clean}_${idx}")
    if(DEFINED offset AND NOT offset EQUAL 0 )
      list(APPEND block_attr "size = ${offset}")
    elseif(DEFINED offset AND offset STREQUAL 0 )
      # Do nothing
    endif()
    if(sort)
      if(${sort} STREQUAL NAME)
        list(APPEND block_attr "alphabetical order")
      endif()
    endif()
    if(align)
      list(APPEND block_attr "alignment = ${align}")
    endif()

    # LD
    # There are two ways to include more than one section:
    #
    # *(.text .rdata)
    # *(.text) *(.rdata)
    #
    # The difference between these is the order in which
    # the `.text' and `.rdata' input sections will appear in the output section.
    # In the first example, they will be intermingled,
    # appearing in the same order as they are found in the linker input.
    # In the second example, all `.text' input sections will appear first,
    # followed by all `.rdata' input sections.
    #
    # ILINK solved by adding 'fixed order'
    if(NOT sort AND NOT first)
      list(APPEND block_attr "fixed order")
    endif()

    list(JOIN block_attr ", " block_attr_str)
    if(block_attr_str)
      set(TEMP "${TEMP} with ${block_attr_str}")
    endif()
    set(block_attr)
    set(block_attr_str)

    if(empty)
      set(TEMP "${TEMP}\n  {")
      set(empty FALSE)
    endif()

    list(GET input -1 last_input)

    set(TEMP "${TEMP} {")
    if(NOT DEFINED input AND NOT any)
      set(TEMP "${TEMP} }")
    endif()

    foreach(setting ${input})
      # message("setting   ${setting}")

      if(first)
        set(TEMP "${TEMP} first")
        set(first "")
      endif()

      if(${setting} STREQUAL .ramfunc)
        set(TEMP "${TEMP} section .textrw,")
      endif()

      set(section_type "")

      # build for ram, no section_type
      # if("${lma}" STREQUAL "${vma}")
      #		# if("${vma}" STREQUAL "")
      #           set(section_type "")
      #		# else()
      #		#   set(section_type " readwrite")
      #		# endif()
      # elseif(NOT "${vma}" STREQUAL "")
      #		set(section_type " readwrite")
      # elseif(NOT "${lma}" STREQUAL "")
      #		set(section_type " readonly")
      # else()
      #		message(FATAL_ERROR "How to handle this? lma=${lma} vma=${vma}")
      # endif()

      set(TEMP "${TEMP}${section_type} section ${setting}")
      set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${setting}")
      set(section_type "")

      # message("${setting} STREQUAL ${last_input}")
      if("${setting}" STREQUAL "${last_input}")
        set(TEMP "${TEMP} }")
      else()
        set(TEMP "${TEMP}, ")
      endif()

      # set(TEMP "${TEMP}\n    *.o(${setting})")
    endforeach()

    if(any)
      if(NOT flags)
        message(FATAL_ERROR ".ANY requires flags to be set.")
      endif()
      set(ANY_FLAG "")
      foreach(flag ${flags})
        # message("flag == ${flag}")
        if("${flag}" STREQUAL +RO OR "${flag}" STREQUAL +XO)
          set(ANY_FLAG "readonly")
        elseif("${flag}" STREQUAL +RW)
          set(ANY_FLAG "readwrite")
        elseif("${flag}" STREQUAL +ZI)
          set(ANY_FLAG "zeroinit")
          set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "${ANY_FLAG}")
        endif()
      endforeach()
      set(TEMP "${TEMP} ${ANY_FLAG} }")
    endif()

    if(DEFINED symbol_end)
      set(TEMP "${TEMP},\n  section ${symbol_end}")
      set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${symbol_end}")
    endif()
    if (${length} GREATER 0)
      if(NOT "${idx}" STREQUAL "${last_index}")
        set(TEMP "${TEMP},")
      elseif()
      endif()
    endif()

    set(symbol_start)
    set(symbol_end)
  endforeach()
  set(next_indicies)

  set(last_index)
  set(last_input)
  set(TEMP "${TEMP}")

  if(NOT nosymbols)
    set(TEMP "${TEMP},\n  section __${name_clean}_end")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section __${name_clean}_end")
  endif()

  foreach(end_symbol ${end_syms})
    set(TEMP "${TEMP},\n  section ${end_symbol}")
    set_property(GLOBAL APPEND PROPERTY ILINK_CURRENT_SECTIONS "section ${end_symbol}")
  endforeach()

  set(TEMP "${TEMP}\n};")

  get_property(type GLOBAL PROPERTY ${parent}_OBJ_TYPE)
  # message("type ${type}")

  if(${type} STREQUAL REGION)
    get_property(name GLOBAL PROPERTY ${parent}_NAME)
    get_property(address GLOBAL PROPERTY ${parent}_ADDRESS)
    get_property(size GLOBAL PROPERTY ${parent}_SIZE)

    # message("name ${name}")
    # message("address ${address}")
    # message("size ${size}")

  endif()

  get_property(current_sections GLOBAL PROPERTY ILINK_CURRENT_SECTIONS)

  if(DEFINED group_parent_vma AND DEFINED group_parent_lma)
    if(DEFINED current_sections)
      set(TEMP "${TEMP}\ninitialize by address_translation\n")
      set(TEMP "${TEMP}{\n")
      foreach(section ${current_sections})
        set(TEMP "${TEMP}  ${section},\n")
      endforeach()
      set(TEMP "${TEMP}};")
      set(current_sections)
    endif()
  endif()

  # message("TEMP == ${TEMP}")

  set(${STRING_STRING} "${${STRING_STRING}}\n${TEMP}\n" PARENT_SCOPE)
endfunction()

function(symbol_to_string)
  cmake_parse_arguments(STRING "" "SYMBOL;STRING" "" ${ARGN})

  get_property(name     GLOBAL PROPERTY ${STRING_SYMBOL}_NAME)
  get_property(expr     GLOBAL PROPERTY ${STRING_SYMBOL}_EXPR)
  get_property(size     GLOBAL PROPERTY ${STRING_SYMBOL}_SIZE)
  get_property(symbol   GLOBAL PROPERTY ${STRING_SYMBOL}_SYMBOL)
  get_property(subalign GLOBAL PROPERTY ${STRING_SYMBOL}_SUBALIGN)

  # message("\nsymbol_to_string")
  # message("name     ${name}")
  # message("expr     ${expr}")
  # message("size     ${size}")
  # message("symbol   ${symbol}")
  # message("subalign ${subalign}")

  string(REPLACE "\\" "" expr "${expr}")
  string(REGEX MATCHALL "@([^@]*)@" match_res ${expr})

  foreach(match ${match_res})
    string(REPLACE "@" "" match ${match})
    get_property(symbol_val GLOBAL PROPERTY SYMBOL_TABLE_${match})
    string(REPLACE "@${match}@" "${match}" expr ${expr})
  endforeach()

  list(LENGTH match_res match_res_count)

  if(match_res_count)
    if(${match_res_count} GREATER 1)
      set(${STRING_STRING}
        "${${STRING_STRING}}define image symbol ${symbol} = ${expr};\n"
        )
    else()
      if(expr MATCHES "Base|Limit|Length")
        # Anything like $$Base/$$Limit/$$Length should be an image symbol
        set(${STRING_STRING}
          "${${STRING_STRING}}define image symbol ${symbol} = ${expr};\n"
          )
      else()
        list(GET match_res 0 match)
        string(REPLACE "@" "" match ${match})
        # message("match == ${match}")
        get_property(symbol_val GLOBAL PROPERTY SYMBOL_TABLE_${match})
        # message("symbol_val == ${symbol_val}")
        if(symbol_val)
          set(${STRING_STRING}
            "${${STRING_STRING}}define image symbol ${symbol} = ${expr};\n"
            )
        else()
          # Treatmen of "zephyr_linker_symbol(SYMBOL z_arm_platform_init EXPR "@SystemInit@")"
          set_property(GLOBAL APPEND PROPERTY SYMBOL_STEERING_FILE
            "--redirect ${symbol}=${expr}\n"
            )
        endif()
      endif()
    endif()
  else()
    set(${STRING_STRING}
      "${${STRING_STRING}}define exported symbol ${symbol} = ${expr};\n"
      )
  endif()
  set(${STRING_STRING} ${${STRING_STRING}} PARENT_SCOPE)
endfunction()

include(${CMAKE_CURRENT_LIST_DIR}/../linker_script_common.cmake)

if(DEFINED STEERING_C)
  get_property(symbols_c GLOBAL PROPERTY SYMBOL_STEERING_C)
  get_property(sections_c GLOBAL PROPERTY SECTION_STEERING_C)
  file(WRITE ${STEERING_C}  "/* AUTO-GENERATED - Do not modify\n")
  file(APPEND ${STEERING_C} " * AUTO-GENERATED - All changes will be lost\n")
  file(APPEND ${STEERING_C} " */\n")
  file(APPEND ${STEERING_C} "\n")

  file(APPEND ${STEERING_C} "#include <stddef.h>\n")
  file(APPEND ${STEERING_C} "#include <stdint.h>\n")
  file(APPEND ${STEERING_C} "#include <intrinsics.h>\n")
  file(APPEND ${STEERING_C} "\n")

  foreach(section ${sections_c})
    file(APPEND ${STEERING_C} "${section}")
  endforeach()
  file(APPEND ${STEERING_C} "\n")
  foreach(symbol ${symbols_c})
    file(APPEND ${STEERING_C} "extern char ${symbol}[];\n")
  endforeach()

  file(APPEND ${STEERING_C} "\nint __ilinkarm_symbol_steering(void) {\n")
  file(APPEND ${STEERING_C} "\tint res=-1;\n")
  foreach(symbol ${symbols_c})
    file(APPEND ${STEERING_C} "\tres = res & (int)${symbol};\n")
  endforeach()
  file(APPEND ${STEERING_C} "\treturn res;\n")
  file(APPEND ${STEERING_C} "\t;\n}\n")
endif()

if(DEFINED STEERING_FILE)
  get_property(steering_content GLOBAL PROPERTY SYMBOL_STEERING_FILE)
  file(WRITE ${STEERING_FILE}  "/* AUTO-GENERATED - Do not modify\n")
  file(APPEND ${STEERING_FILE} " * AUTO-GENERATED - All changes will be lost\n")
  file(APPEND ${STEERING_FILE} " */\n")

  file(APPEND ${STEERING_FILE} ${steering_content})
endif()
