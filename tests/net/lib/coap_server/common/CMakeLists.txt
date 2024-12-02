# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(coap_service_defines)

FILE(GLOB app_sources src/*.c)
target_sources(app PRIVATE ${app_sources})

zephyr_linker_sources(DATA_SECTIONS sections-ram.ld)
zephyr_iterable_section(NAME coap_resource_service_A GROUP DATA_REGION ${XIP_ALIGN_WITH_INPUT} SUBALIGN ${CONFIG_LINKER_ITERABLE_SUBALIGN})
zephyr_iterable_section(NAME coap_resource_service_B GROUP DATA_REGION ${XIP_ALIGN_WITH_INPUT} SUBALIGN ${CONFIG_LINKER_ITERABLE_SUBALIGN})
zephyr_iterable_section(NAME coap_resource_service_C GROUP DATA_REGION ${XIP_ALIGN_WITH_INPUT} SUBALIGN ${CONFIG_LINKER_ITERABLE_SUBALIGN})
