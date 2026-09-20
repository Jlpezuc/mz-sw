#ifndef MZ_ADCLTC2311_HW_H
#define MZ_ADCLTC2311_HW_H


// includes

#include <stdint.h>
#include "../../mz/mz_fixedpoint/mz_fixedpoint.h"

// function declarations

void mz_adcLtc2311_hw_write_cr(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_spi_cr(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_spi_cfgr(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_master_channel(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_channel(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_value(uint32_t base_address,uint32_t value);
void mz_adcLtc2311_hw_write_value_signed(uint32_t base_address,int32_t value);
void mz_adcLtc2311_hw_write_value_fixedpoint(uint32_t base_address, float value,struct mz_fixedpoint_definition_t fixedpoint_definition);

void mz_adcLtc2311_hw_write_adc_available(uint32_t base_address, uint32_t value);

uint32_t mz_adcLtc2311_hw_read_cr(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_spi_cr(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_spi_cfgr(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_master_channel(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_channel(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_master_finish(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_master_si_finish(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_master_busy(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_value(uint32_t base_address);
uint32_t mz_adcLtc2311_hw_read_adc_available(uint32_t base_address);

#endif // MZ_ADCLTC2311_HW_H
