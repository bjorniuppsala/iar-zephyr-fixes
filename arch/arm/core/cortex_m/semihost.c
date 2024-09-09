/*
 * Copyright (c) 2022, Commonwealth Scientific and Industrial Research
 * Organisation (CSIRO) ABN 41 687 119 230.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/arch/common/semihost.h>

#if 1

#ifdef __ICCARM__
// IAR WA VAAK-88: __asm instead of __asm__

#ifndef __asm__
#define __asm__ __asm
#endif

// IAR WA VAAK-7: volatile instead of __volatile__

#ifndef __volatile__
#define __volatile__ volatile
#endif

// IAR WA VAAK-8: Using _Pragma location instead of __asm__

long semihost_exec(enum semihost_instr instr, void *args)
{
	int ret;
	// IAR WA VAAK-8: Using specific registers 

	__asm__ __volatile__("bkpt 0xab" : "=r0"(ret) : "r0"(instr), "r1"(args) : "memory");
	return ret;
}

#else

	long semihost_exec(enum semihost_instr instr, void *args)
{
	register unsigned int r0 __asm__("r0") = instr;
	register void *r1 __asm__("r1") = args;
	register int ret __asm__("r0");

	__asm__ __volatile__("bkpt 0xab" : "=r"(ret) : "r"(r0), "r"(r1) : "memory");
	return ret;
}
#endif
