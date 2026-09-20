#include "mz_adcMax11331_ip_core_init.h"
#include "../mz/mz_HAL.h"
#include "../IP_Cores/mz_adcMax11331/mz_adcMax11331.h"
#include "xparameters.h"
#include <stdint.h>
#include <stdbool.h>

#define XPAR_A1_ADC_MAX11331_IP_CORE_FREQUENCY 100000000U
#define DEFAULT_MAX11331_CONVERSION_FACTOR 1.0f
#define DEFAULT_MAX11331_INTEGER_BITS 14
#define DEFAULT_MAX11331_FRACTIONAL_BITS 4
#define DEFAULT_MAX11331_OFFSET 0

void mz_adcMax11331_ip_core_init(void)
{
   //Parameter set for one MAX11331 chip, thus one master
   struct mz_adcMax11331_config_t default_configuration = {
        .base_address = XPAR_MZ_ANALOG_ADAPTER_A3_ADAPTER_ADC_MAX11331_TOP_0_BASEADDR,
        .ip_clk_frequency_Hz = 100000000U,
        .channel_config = {
            .conversion_factor = DEFAULT_MAX11331_CONVERSION_FACTOR,
            .conversion_factor_definition = {
                .is_signed = true,
                .integer_bits = DEFAULT_MAX11331_INTEGER_BITS,
                .fractional_bits = DEFAULT_MAX11331_FRACTIONAL_BITS},
            .offset = DEFAULT_MAX11331_OFFSET,
        },
        .trigger_mode=mz_adcMax11331_continuous_trigger,
        .cpol = 1U,
        .cpha = 1U,
        .master_select = MZ_ADCMAX11331_MASTER1,
        .channel_select = MZ_ADCMAX11331_CH1 | MZ_ADCMAX11331_CH2 | MZ_ADCMAX11331_CH3 | MZ_ADCMAX11331_CH4 | MZ_ADCMAX11331_CH5 | MZ_ADCMAX11331_CH6 | MZ_ADCMAX11331_CH7 | MZ_ADCMAX11331_CH8 | MZ_ADCMAX11331_CH9 | MZ_ADCMAX11331_CH10 | MZ_ADCMAX11331_CH11 | MZ_ADCMAX11331_CH12 | MZ_ADCMAX11331_CH13 | MZ_ADCMAX11331_CH14 | MZ_ADCMAX11331_CH15 | MZ_ADCMAX11331_CH16,
        .clk_div = MZ_ADCMAX11331_SPI_CLK_16_67MHZ};

   // A3 is the only MAX11331 adapter board in mzsys (MZ_ADCMAX11331_MAX_INSTANCES = 1).
   // The values are read through the DataMover (mz_dataMover), so the instance pointer is not needed.
   (void)mz_adcMax11331_init(default_configuration);
}
