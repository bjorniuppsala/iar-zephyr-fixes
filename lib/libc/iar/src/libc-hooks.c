/*
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <stdio.h>

static int _stdout_hook_default(int c)
{
  (void)(c);  /* Prevent warning about unused argument */

  return EOF;
}

static int (*_stdout_hook)(int) = _stdout_hook_default;

void __stdout_hook_install(int (*hook)(int))
{
  _stdout_hook = hook;
}

int fputc(int c, FILE *f)
{
  return (_stdout_hook)(c);
}

#pragma weak __write
size_t __write(int handle,
               const unsigned char *buf,
               size_t bufSize)
{
  size_t nChars = 0;
  /* Check for the command to flush all handles */
  if (handle == -1)
  {
    return 0;
  }
  /* Check for stdout and stderr
     (only necessary if FILE descriptors are enabled.) */
  if (handle != 1 && handle != 2)
  {
    return -1;
  }
  for (/* Empty */; bufSize > 0; --bufSize)
  {
    int ret = (_stdout_hook)(*buf);
    if (ret == EOF)
    {
      break;
    }
    ++buf;
    ++nChars;
  }
  return nChars;
}

#include <time.h>
/**
 * @file
 * @brief Defines additional time related functions based on POSIX
 */
#if !CONFIG_COMMON_LIBC_ASCTIME_R
char *asctime_r(const struct tm *ZRESTRICT tp,
                char *ZRESTRICT buf)
{
  asctime_s(buf, sizeof buf, tp);
  return buf;
}
#endif
#if !CONFIG_COMMON_LIBC_CTIME_R
char *ctime_r(const time_t *clock,
              char *buf)
{
  ctime_s(buf, sizeof buf, clock);
  return buf;
}
#endif
#if !CONFIG_COMMON_LIBC_GMTIME_R
struct tm *gmtime_r(const time_t *ZRESTRICT timep,
                    struct tm *ZRESTRICT result)
{
  *result = *gmtime(timep);
  return result;
}
#endif
#if !CONFIG_COMMON_LIBC_LOCALTIME_R_UTC
struct tm *localtime_r(const time_t *ZRESTRICT timer, struct tm *ZRESTRICT result)
{
  *result = *localtime(timer);
  return result;
}
#endif

