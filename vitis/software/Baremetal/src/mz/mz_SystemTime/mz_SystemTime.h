#ifndef MZ_SYSTEMTIME_H_
#define MZ_SYSTEMTIME_H_

#include <stdint.h>
#include <stdbool.h>

void mz_SystemTime_init();
void mz_SystemTime_ISR_Tic(); // start the stopwatch
void mz_SystemTime_ISR_Toc(); // stop the stopwatch

// Getter functions
float mz_SystemTime_GetIsrPeriodInUs();
float mz_SystemTime_GetIsrExectionTimeInUs();
uint64_t mz_SystemTime_GetInterruptCounter();
uint64_t mz_SystemTime_GetUptimeInUs();
unsigned int mz_SystemTime_GetUptimeInMs();
unsigned int mz_SystemTime_GetUptimeInSec();
unsigned int mz_SystemTime_GetUptimeInMin();
float mz_SystemTime_GetGlobalTimeInSec();

#endif