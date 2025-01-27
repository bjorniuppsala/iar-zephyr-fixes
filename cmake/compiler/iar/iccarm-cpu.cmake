# SPDX-License-Identifier: Apache-2.0

# Determines what argument to give to --cpu= based on the
# KConfig'uration and sets this to ICCARM_CPU

if("${ARCH}" STREQUAL "arm")
  if    (CONFIG_CPU_CORTEX_M0)
    set(ICCARM_CPU Cortex-M0)
  elseif(CONFIG_CPU_CORTEX_M0PLUS)
    set(ICCARM_CPU Cortex-M0+)
  elseif(CONFIG_CPU_CORTEX_M1)
    set(ICCARM_CPU Cortex-M1)
  elseif(CONFIG_CPU_CORTEX_M3)
    set(ICCARM_CPU Cortex-M3)
  elseif(CONFIG_CPU_CORTEX_M4)
    set(ICCARM_CPU Cortex-M4)
  elseif(CONFIG_CPU_CORTEX_M7)
    set(ICCARM_CPU Cortex-M7)
  elseif(CONFIG_CPU_CORTEX_M23)
    set(ICCARM_CPU Cortex-M23)
  elseif(CONFIG_CPU_CORTEX_M33)
    if    (CONFIG_ARMV8_M_DSP)
      set(ICCARM_CPU Cortex-M33)
    else()
      set(ICCARM_CPU Cortex-M33.no_dsp)
    endif()
  elseif(CONFIG_CPU_CORTEX_M55)
    if    (CONFIG_ARMV8_1_M_MVEF)
      set(ICCARM_CPU Cortex-M55)
    elseif(CONFIG_ARMV8_1_M_MVEI)
      # set(ICCARM_CPU cortex-m55.no_mve.fp)
      set(ICCARM_CPU Cortex-M55.no_mve)
    elseif(CONFIG_ARMV8_M_DSP)
      set(ICCARM_CPU Cortex-M55.no_mve)
    else()
      set(ICCARM_CPU Cortex-M55.no_dsp)
    endif()
  elseif(CONFIG_CPU_CORTEX_R4)
    if(CONFIG_FPU AND CONFIG_CPU_HAS_VFP)
      set(ICCARM_CPU Cortex-R4F)
    else()
      set(ICCARM_CPU Cortex-R4)
    endif()
  elseif(CONFIG_CPU_CORTEX_R5)
    set(ICCARM_CPU Cortex-R5)
    if(CONFIG_FPU AND CONFIG_CPU_HAS_VFP)
      if(NOT CONFIG_VFP_FEATURE_DOUBLE_PRECISION)
        set(ICCARM_CPU ${ICCARM_CPU}+fp.sp)
      endif()
    else()
      set(ICCARM_CPU ${ICCARM_CPU}+fp.dp)
    endif()
  elseif(CONFIG_CPU_CORTEX_R7)
    set(ICCARM_CPU Cortex-R7)
    if(CONFIG_FPU AND CONFIG_CPU_HAS_VFP)
      if(NOT CONFIG_VFP_FEATURE_DOUBLE_PRECISION)
        set(ICCARM_CPU ${ICCARM_CPU}+fp.sp)
      endif()
    else()
      set(ICCARM_CPU ${ICCARM_CPU}+fp.dp)
    endif()
  elseif(CONFIG_CPU_CORTEX_R52)
    set(ICCARM_CPU Cortex-R52)
    if(CONFIG_FPU AND CONFIG_CPU_HAS_VFP)
      if(NOT CONFIG_VFP_FEATURE_DOUBLE_PRECISION)
        set(ICCARM_CPU ${ICCARM_CPU}+fp.sp)
      endif()
    endif()
  elseif(CONFIG_CPU_CORTEX_A9)
    set(ICCARM_CPU Cortex-A9)
  else()
    message(FATAL_ERROR "Expected CONFIG_CPU_CORTEX_x to be defined")
  endif()
elseif("${ARCH}" STREQUAL "arm64")
  if(CONFIG_CPU_CORTEX_A53)
    set(ICCARM_CPU Cortex-A53)
  elseif(CONFIG_CPU_CORTEX_A55)
    set(ICCARM_CPU Cortex-A55)
  elseif(CONFIG_CPU_CORTEX_A76)
    set(ICCARM_CPU cortex-a76)
  elseif(CONFIG_CPU_CORTEX_A76_A55)
    set(ICCARM_CPU cortex-a76)
  elseif(CONFIG_CPU_CORTEX_A72)
    set(ICCARM_CPU Cortex-A72)
  elseif(CONFIG_CPU_CORTEX_R82)
    set(ICCARM_CPU Cortex-R82)
  endif()
endif()
