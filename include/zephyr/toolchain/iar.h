/*
 * Copyright (c) 2022 IAR Systems AB
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef ZEPHYR_INCLUDE_TOOLCHAIN_IAR_H_
#define ZEPHYR_INCLUDE_TOOLCHAIN_IAR_H_

#ifdef __ICCARM__
#include "iar/iccarm.h"
#endif
#ifdef __ICCRISCV__
#include "iar/iccriscv.h"
#endif

#endif /* ZEPHYR_INCLUDE_TOOLCHAIN_ICCARM_H_ */
