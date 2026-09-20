#include <stdint.h>
#include "../mz_HAL.h"

#include <xtmrctr.h>
#include "xparameters.h"

#define MZ_AXI_TIMER_CLOCK_FREQ XPAR_MZ_SYSTEM_TIMER_UPTIME_64BIT_CLOCK_FREQ_HZ

void mz_AxiTimer64Bit_init();
uint64_t mz_AxiTimer64Bit_ReadValue64Bit();
