/*
 * Copyright 2024 IAR Systems AB
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef ZEPHYR_LIB_LIBC_ICCARM_INCLUDE_SYS__TIMESPEC_H_
#define ZEPHYR_LIB_LIBC_ICCARM_INCLUDE_SYS__TIMESPEC_H_

#include <sys/types.h>

#if !defined(__timespec_defined)
#define __timespec_defined
struct timespec {
    time_t tv_sec;
    long tv_nsec;
};
#endif

#endif /* ZEPHYR_LIB_LIBC_ICCARM_INCLUDE_SYS__TIMESPEC_H_ */
