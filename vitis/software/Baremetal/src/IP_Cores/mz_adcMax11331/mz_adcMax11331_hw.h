#ifndef MZ_ADCMAX11331_HW_H
#define MZ_ADCMAX11331_HW_H


// includes

#include <stdint.h>
#include "../../mz/mz_fixedpoint/mz_fixedpoint.h"

// function declarations

void mz_adcMax11331_hw_write_spi_cfgr(uint32_t base_address,uint32_t value);
void mz_adcMax11331_hw_write_master_channel(uint32_t base_address,uint32_t value);

uint32_t mz_adcMax11331_hw_read_spi_cfgr(uint32_t base_address);
uint32_t mz_adcMax11331_hw_read_master_channel(uint32_t base_address);


#endif // MZ_ADCMAX11331_HW_H
