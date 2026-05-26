// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

#if defined(__APPLE__)
#include <mach/mach_time.h>
#elif defined(_POSIX_TIMERS) && _POSIX_TIMERS > 0
#include <time.h>
#else
#include <time.h>
#endif

double rhodonite_ecs_bench_monotonic_ms(void) {
#if defined(__APPLE__)
  static mach_timebase_info_data_t timebase = {0, 0};
  if (timebase.denom == 0) {
    mach_timebase_info(&timebase);
  }
  uint64_t ticks = mach_absolute_time();
  double ns = (double)ticks * (double)timebase.numer / (double)timebase.denom;
  return ns / 1000000.0;
#elif defined(CLOCK_MONOTONIC)
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1000000.0;
#else
  return (double)clock() * 1000.0 / (double)CLOCKS_PER_SEC;
#endif
}
