#include "../../mz/mz_global_configuration.h"
#if MZ_ADCLTC2311_MAX_INSTANCES > 0U
#include <stdbool.h>
#include <stdint.h>
#include "../../mz/mz_HAL.h"
#include "mz_adcLtc2311.h"
#include "mz_adcLtc2311_private_utilities.h"
#include "mz_adcLtc2311_hw.h"

#define CONVERSION_FACTOR_NUMBER_OF_BITS 18

struct mz_adcLtc2311_t
{
    bool is_ready;
    struct mz_adcLtc2311_config_t config;
};

static uint32_t instance_counter = 0U;
static mz_adcLtc2311_t instances[MZ_ADCLTC2311_MAX_INSTANCES] = {0};

static mz_adcLtc2311_t *mz_adcLtc2311_allocation(void);

static mz_adcLtc2311_t *mz_adcLtc2311_allocation(void)
{
    mz_assert(instance_counter < MZ_ADCLTC2311_MAX_INSTANCES);
    mz_adcLtc2311_t *self = &instances[instance_counter];
    mz_assert_false(self->is_ready);
    instance_counter++;
    self->is_ready = true;
    return (self);
}

mz_adcLtc2311_t *mz_adcLtc2311_init(struct mz_adcLtc2311_config_t config)
{
    mz_adcLtc2311_t *self = mz_adcLtc2311_allocation();
    mz_assert_not_zero(config.ip_clk_frequency_Hz);
    mz_assert_not_zero(config.base_address);
    mz_assert(config.napping_spi_masters == 0U);
    mz_assert(config.sleeping_spi_masters == 0U);
    mz_assert(config.channel_config.conversion_factor != 0.0f);
   // mz_assert(config.cpol != 0U);
  //  mz_assert(config.cpha == 0U);
    mz_assert(config.spi_master_config.samples > 0U);
    self->config = config;
    mz_adcLtc2311_init_set_parameters(self);
    return (self);
}

void mz_adcLtc2311_software_reset(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);
    adc_cr |= MZ_ADCLTC2311_CR_SW_RESET;
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
}

void mz_adcLtc2311_software_trigger(mz_adcLtc2311_t *self, uint32_t spi_masters)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    // if no channel is selected with the function call, use the value in the config struct instead
    if (spi_masters == 0)
    {
        mz_adcLtc2311_hw_write_master_channel(self->config.base_address, self->config.master_select);
    }
    else
    {
        mz_adcLtc2311_hw_write_master_channel(self->config.base_address, spi_masters);
    }
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);
    adc_cr |= MZ_ADCLTC2311_CR_TRIGGER;
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
}

void mz_adcLtc2311_set_continuous_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);
    adc_cr |= MZ_ADCLTC2311_CR_MODE;
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
}

void mz_adcLtc2311_set_triggered_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address); // read out current settings of the control register
    adc_cr &= ~MZ_ADCLTC2311_CR_MODE;                                      // AND operation of current settings and 0x111...0, leaving all bits but the bit 0 as they are and setting bit 0 to false, entering triggered mode
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
}

void mz_adcLtc2311_set_software_trigger_mode(mz_adcLtc2311_t *self)
{
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);
    adc_cr |= MZ_ADCLTC2311_CR_SW_TRIGGER_MODE;
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
}

void mz_adcLtc2311_set_pl_trigger_mode(mz_adcLtc2311_t *self)
{
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);
    adc_cr &= ~MZ_ADCLTC2311_CR_SW_TRIGGER_MODE;
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
}

void mz_adcLtc2311_set_master_select(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    self->config.master_select = value;
}

void mz_adcLtc2311_set_channel_select(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    self->config.channel_select = value;
}

void mz_adcLtc2311_set_conversion_factor(mz_adcLtc2311_t *self, float value, struct mz_fixedpoint_definition_t fixedpoint_definition)

{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(fixedpoint_definition.is_signed); // IP-Core only uses signed fixed point data type
    mz_assert(CONVERSION_FACTOR_NUMBER_OF_BITS >= (fixedpoint_definition.fractional_bits + fixedpoint_definition.integer_bits) );
    self->config.channel_config.conversion_factor = value;
    self->config.channel_config.conversion_factor_definition = fixedpoint_definition;
}

void mz_adcLtc2311_set_offset(mz_adcLtc2311_t *self, int value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    self->config.channel_config.offset = value;
}

void mz_adcLtc2311_set_samples(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(value > 0);
    mz_assert(mz_adcLtc2311_check_32_bit_int_if_msb_not_set(value));
    self->config.spi_master_config.samples = value;
}

void mz_adcLtc2311_set_max_attempts(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    self->config.max_attempts = value;
}

void mz_adcLtc2311_set_sample_time(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(mz_adcLtc2311_check_32_bit_int_if_msb_not_set(value));
    self->config.spi_master_config.sample_time = value;
}

void mz_adcLtc2311_set_pre_delay(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(
        mz_adcLtc2311_check_32_bit_int_if_not_more_sign_bits_set_than_spec(
            value,
            MZ_ADCLTC2311_SPI_CFGR_PRE_DELAY_WIDTH));
    self->config.pre_delay = value;
}

void mz_adcLtc2311_set_post_delay(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(
        mz_adcLtc2311_check_32_bit_int_if_not_more_sign_bits_set_than_spec(
            value,
            MZ_ADCLTC2311_SPI_CFGR_POST_DELAY_WIDTH));
    self->config.post_delay = value;
}

void mz_adcLtc2311_set_clk_div(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(
        mz_adcLtc2311_check_32_bit_int_if_not_more_sign_bits_set_than_spec(
            value,
            MZ_ADCLTC2311_SPI_CFGR_CLK_DIV_WIDTH));
    self->config.clk_div = value;
}

void mz_adcLtc2311_set_cpha(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    // CPHA must be 0 for correct operation
    mz_assert(value == 0);
    self->config.cpha = value;
}

void mz_adcLtc2311_set_cpol(mz_adcLtc2311_t *self, uint32_t value)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    // CPOL must be 1 for correct operation
    mz_assert(value > 0);
    self->config.cpol = value;
}

uint32_t mz_adcLtc2311_get_master_select(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.master_select);
}

uint32_t mz_adcLtc2311_get_channel_select(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.channel_select);
}

float mz_adcLtc2311_get_conversion_factor(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.channel_config.conversion_factor);
}

int32_t mz_adcLtc2311_get_offset(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.channel_config.offset);
}

uint32_t mz_adcLtc2311_get_samples(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.spi_master_config.samples);
}

uint32_t mz_adcLtc2311_get_max_attempts(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.max_attempts);
}

uint32_t mz_adcLtc2311_get_sample_time(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.spi_master_config.sample_time);
}

uint32_t mz_adcLtc2311_get_pre_delay(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.pre_delay);
}

uint32_t mz_adcLtc2311_get_post_delay(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.post_delay);
}

uint32_t mz_adcLtc2311_get_clk_div(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.clk_div);
}

uint32_t mz_adcLtc2311_get_cpha(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.cpha);
}

uint32_t mz_adcLtc2311_get_cpol(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.cpol);
}

uint32_t mz_adcLtc2311_get_napping_masters(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.napping_spi_masters);
}

uint32_t mz_adcLtc2311_get_sleeping_masters(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.sleeping_spi_masters);
}

uint32_t mz_adcLtc2311_get_base_address(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.base_address);
}

uint32_t mz_adcLtc2311_get_error_code(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    return (self->config.error_code);
}

// update functions
uint32_t mz_adcLtc2311_update_conversion_factor(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    mz_assert(self->config.channel_config.conversion_factor_definition.is_signed); // IP-Core only uses signed fixed point data type
    mz_assert(CONVERSION_FACTOR_NUMBER_OF_BITS >= (self->config.channel_config.conversion_factor_definition.fractional_bits + self->config.channel_config.conversion_factor_definition.integer_bits));

    uint32_t return_value = MZ_SUCCESS;
    // Get the current state of the control register
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);

    // Reset all bits that determine the meaning of the value
    adc_cr &= ~(MZ_ADCLTC2311_CR_CONFIG_VALUE_0 | MZ_ADCLTC2311_CR_CONFIG_VALUE_1 | MZ_ADCLTC2311_CR_CONFIG_VALUE_2);
    // Set the appropriate bits to determine the meaning of the value
    // Set the VALUE_VALID bit as well to trigger the update
    adc_cr |= MZ_ADCLTC2311_CR_CONV_VALUE_VALID | MZ_ADCLTC2311_CR_CONFIG_VALUE_0;

    // Perform the actual writing to the hardware registers
    // Selection, which channels shall be updated
    mz_adcLtc2311_hw_write_master_channel(self->config.base_address, self->config.master_select);
    mz_adcLtc2311_hw_write_channel(self->config.base_address, self->config.channel_select);
    // Write the desired factor
    mz_adcLtc2311_hw_write_value_fixedpoint(self->config.base_address, self->config.channel_config.conversion_factor, self->config.channel_config.conversion_factor_definition);
    // Trigger the update
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);

    // Wait for the acknowledgement
    return_value = mz_adcLtc2311_cr_wait_for_value_acknowledgement(self->config.base_address, self->config.max_attempts);

    return return_value;
}

uint32_t mz_adcLtc2311_update_offset(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t return_value = MZ_SUCCESS;
    // Get the current state of the control register
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);

    // Reset all bits that determine the meaning of the value
    adc_cr &= ~(MZ_ADCLTC2311_CR_CONFIG_VALUE_0 | MZ_ADCLTC2311_CR_CONFIG_VALUE_1 | MZ_ADCLTC2311_CR_CONFIG_VALUE_2);
    // Set the appropriate bits to determine the meaning of the value
    // Set the VALUE_VALID bit as well to trigger the update
    adc_cr |= MZ_ADCLTC2311_CR_CONV_VALUE_VALID;

    // Perform the actual writing to the hardware registers
    // Selection, which channels shall be updated
    mz_adcLtc2311_hw_write_master_channel(self->config.base_address, self->config.master_select);
    mz_adcLtc2311_hw_write_channel(self->config.base_address, self->config.channel_select);
    // Write the desired factor
    mz_adcLtc2311_hw_write_value_signed(self->config.base_address, self->config.channel_config.offset);
    // Trigger the update
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);

    // Wait for the acknowledgement
    return_value = mz_adcLtc2311_cr_wait_for_value_acknowledgement(self->config.base_address, self->config.max_attempts);

    return return_value;
}

uint32_t mz_adcLtc2311_update_samples(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t return_value = MZ_SUCCESS;
    // Get the current state of the control register
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);

    // Reset all bits that determine the meaning of the value
    adc_cr &= ~(MZ_ADCLTC2311_CR_CONFIG_VALUE_0 | MZ_ADCLTC2311_CR_CONFIG_VALUE_1 | MZ_ADCLTC2311_CR_CONFIG_VALUE_2);
    // Set the appropriate bits to determine the meaning of the value
    // Set the VALUE_VALID bit as well to trigger the update
    adc_cr |= MZ_ADCLTC2311_CR_CONV_VALUE_VALID | MZ_ADCLTC2311_CR_CONFIG_VALUE_1;

    // Perform the actual writing to the hardware registers
    // Selection, which channels shall be updated
    mz_adcLtc2311_hw_write_master_channel(self->config.base_address, self->config.master_select);
    // Write the desired factor
    mz_adcLtc2311_hw_write_value(self->config.base_address, self->config.spi_master_config.samples);
    // Trigger the update
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);

    // Wait for the acknowledgement
    return_value = mz_adcLtc2311_cr_wait_for_value_acknowledgement(self->config.base_address, self->config.max_attempts);

    return return_value;
}

uint32_t mz_adcLtc2311_update_sample_time(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    uint32_t return_value = MZ_SUCCESS;
    // Get the current state of the control register
    uint32_t adc_cr = mz_adcLtc2311_hw_read_cr(self->config.base_address);

    // Reset all bits that determine the meaning of the value
    adc_cr &= ~(MZ_ADCLTC2311_CR_CONFIG_VALUE_0 | MZ_ADCLTC2311_CR_CONFIG_VALUE_1 | MZ_ADCLTC2311_CR_CONFIG_VALUE_2);
    // Set the appropriate bits to determine the meaning of the value
    // Set the VALUE_VALID bit as well to trigger the update
    adc_cr |= MZ_ADCLTC2311_CR_CONV_VALUE_VALID | MZ_ADCLTC2311_CR_CONFIG_VALUE_0 | MZ_ADCLTC2311_CR_CONFIG_VALUE_1;

    // Perform the actual writing to the hardware registers
    // Selection, which channels shall be updated
    mz_adcLtc2311_hw_write_master_channel(self->config.base_address, self->config.master_select);
    // Write the desired factor
    mz_adcLtc2311_hw_write_value(self->config.base_address, self->config.spi_master_config.sample_time);
    // Trigger the update
    mz_adcLtc2311_hw_write_cr(self->config.base_address, adc_cr);

    // Wait for the acknowledgement
    return_value = mz_adcLtc2311_cr_wait_for_value_acknowledgement(self->config.base_address, self->config.max_attempts);

    return return_value;
}

void mz_adcLtc2311_update_spi(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);

    // assemble the content of SPI configuration register and write it
    uint32_t spi_cfgr = (self->config.clk_div << MZ_ADCLTC2311_SPI_CFGR_CLK_DIV_LSB) |
                        (self->config.pre_delay << MZ_ADCLTC2311_SPI_CFGR_PRE_DELAY_LSB) |
                        (self->config.post_delay << MZ_ADCLTC2311_SPI_CFGR_POST_DELAY_LSB);
    mz_adcLtc2311_hw_write_spi_cfgr(self->config.base_address, spi_cfgr);

    // update CPHA and CPOL
    uint32_t spi_cr = mz_adcLtc2311_hw_read_spi_cr(self->config.base_address);
    if (self->config.cpha == 0)
    {
        spi_cr &= ~MZ_ADCLTC2311_SPI_CR_CPHA;
    }
    else
    {
        spi_cr |= MZ_ADCLTC2311_SPI_CR_CPHA;
    }

    if (self->config.cpol == 0)
    {
        spi_cr &= ~MZ_ADCLTC2311_SPI_CR_CPOL;
    }
    else
    {
        spi_cr |= MZ_ADCLTC2311_SPI_CR_CPOL;
    }

    mz_adcLtc2311_hw_write_spi_cr(self->config.base_address, spi_cr);
}

// nap and sleep modes

uint32_t mz_adcLtc2311_enter_nap_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    uint32_t return_value = MZ_SUCCESS;
    self->config.error_code = 0;

    // Check if masters have been selected for the operation
    if (self->config.master_select == 0)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NO_SELECTION;
    }
    // Check if the selected masters are already in nap or sleep mode
    else if ((self->config.master_select & self->config.napping_spi_masters) ||
             (self->config.master_select & self->config.sleeping_spi_masters))
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_ALREADY_IN_MODE;
    }
    else
    {
        return_value = mz_adcLtc2311_prepare_manual_operation(self);
        if (return_value == MZ_FAILURE)
        {
            self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_EN_FAILED;
        }
        else
        {
            // perform the hardware action to send the LTC2311 to nap mode
            for (uint32_t i = 0; i < MZ_ADCLTC2311_NAP_PULSES; i++)
            {
                mz_adcLtc2311_spi_set_ss_n(self->config.base_address);
                mz_adcLtc2311_spi_reset_ss_n(self->config.base_address);
            }
            mz_adcLtc2311_spi_set_ss_n(self->config.base_address);

            // capture, which masters entered nap mode
            self->config.napping_spi_masters |= self->config.master_select;

            // signal the hardware that the selected channels are not available
            uint32_t adc_available = mz_adcLtc2311_hw_read_adc_available(self->config.base_address);
            adc_available &= ~(self->config.master_select);
            mz_adcLtc2311_hw_write_adc_available(self->config.base_address, adc_available);

            // Disable manual mode
            return_value = mz_adcLtc2311_disable_manual_mode(self->config.base_address, self->config.max_attempts);
            if (return_value == MZ_FAILURE)
            {
                self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_DIS_FAILED;
            }
        }
    }
    return (return_value);
}

uint32_t mz_adcLtc2311_leave_nap_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    uint32_t return_value = MZ_SUCCESS;
    self->config.error_code = 0;

    // Check if masters have been selected for the operation
    if (self->config.master_select == 0)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NO_SELECTION;
    }
    // Check if the selected master are not in sleep mode
    else if (self->config.master_select & self->config.sleeping_spi_masters)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NOT_IN_MODE;
    }
    // Check if the selected masters are in nap mode
    else
    {
        return_value = mz_adcLtc2311_all_masked_bits_set_in_value(self->config.napping_spi_masters, self->config.master_select);
        if (return_value == MZ_FAILURE)
        {
            self->config.error_code |= MZ_ADCLTC2311_NS_NOT_IN_MODE;
        }
        else
        {
            return_value = mz_adcLtc2311_prepare_manual_operation(self);
            if (return_value == MZ_FAILURE)
            {
                self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_EN_FAILED;
            }
            else
            {
                // perform the hardware action to wake the LTC2311 from nap mode
                mz_adcLtc2311_spi_reset_sclk(self->config.base_address);
                mz_adcLtc2311_spi_set_sclk(self->config.base_address);

                // capture, which masters left nap mode
                self->config.napping_spi_masters &= ~self->config.master_select;

                // signal the hardware that the selected channels are available
                uint32_t adc_available = mz_adcLtc2311_hw_read_adc_available(self->config.base_address);
                adc_available |= self->config.master_select;
                mz_adcLtc2311_hw_write_adc_available(self->config.base_address, adc_available);

                // Disable manual mode
                return_value = mz_adcLtc2311_disable_manual_mode(self->config.base_address, self->config.max_attempts);
                if (return_value == MZ_FAILURE)
                {
                    self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_DIS_FAILED;
                }
            }
        }
    }
    return (return_value);
}

uint32_t mz_adcLtc2311_enter_sleep_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    uint32_t return_value = MZ_SUCCESS;
    self->config.error_code = 0;

    // Check if masters have been selected for the operation
    if (self->config.master_select == 0)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NO_SELECTION;
    }
    // Check if the selected masters are already in nap or sleep mode
    else if ((self->config.master_select & self->config.napping_spi_masters) ||
             (self->config.master_select & self->config.sleeping_spi_masters))
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_ALREADY_IN_MODE;
    }
    else
    {
        return_value = mz_adcLtc2311_prepare_manual_operation(self);
        if (return_value == MZ_FAILURE)
        {
            self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_EN_FAILED;
        }
        else
        {
            // perform the hardware action to send the LTC2311 to sleep mode
            for (uint32_t i = 0; i < MZ_ADCLTC2311_SLEEP_PULSES; i++)
            {
                mz_adcLtc2311_spi_set_ss_n(self->config.base_address);
                mz_adcLtc2311_spi_reset_ss_n(self->config.base_address);
            }
            mz_adcLtc2311_spi_set_ss_n(self->config.base_address);

            // capture, which masters entered sleep mode
            self->config.sleeping_spi_masters |= self->config.master_select;

            // signal the hardware that the selected channels are not available
            uint32_t adc_available = mz_adcLtc2311_hw_read_adc_available(self->config.base_address);
            adc_available &= ~(self->config.master_select);
            mz_adcLtc2311_hw_write_adc_available(self->config.base_address, adc_available);

            // Disable manual mode
            return_value = mz_adcLtc2311_disable_manual_mode(self->config.base_address, self->config.max_attempts);
            if (return_value == MZ_FAILURE)
            {
                self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_DIS_FAILED;
            }
        }
    }
    return (return_value);
}

uint32_t mz_adcLtc2311_leave_sleep_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    mz_assert(self->is_ready);
    uint32_t return_value = MZ_SUCCESS;
    self->config.error_code = 0;

    // Check if masters have been selected for the operation
    if (self->config.master_select == 0)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NO_SELECTION;
    }
    // Check if the selected master are not in nap mode
    else if (self->config.master_select & self->config.napping_spi_masters)
    {
        return_value = MZ_FAILURE;
        self->config.error_code |= MZ_ADCLTC2311_NS_NOT_IN_MODE;
    }
    // Check if the selected masters are in sleep mode
    else
    {
        return_value = mz_adcLtc2311_all_masked_bits_set_in_value(self->config.sleeping_spi_masters, self->config.master_select);
        if (return_value == MZ_FAILURE)
        {
            self->config.error_code |= MZ_ADCLTC2311_NS_NOT_IN_MODE;
        }
        else
        {
            return_value = mz_adcLtc2311_prepare_manual_operation(self);
            if (return_value == MZ_FAILURE)
            {
                self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_EN_FAILED;
            }
            else
            {
                // perform the hardware action to wake the LTC2311 from sleep mode
                mz_adcLtc2311_spi_reset_ss_n(self->config.base_address);
                mz_adcLtc2311_spi_set_ss_n(self->config.base_address);

                // capture, which masters left sleep mode
                self->config.sleeping_spi_masters &= ~self->config.master_select;

                // signal the hardware that the selected channels are available
                uint32_t adc_available = mz_adcLtc2311_hw_read_adc_available(self->config.base_address);
                adc_available |= self->config.master_select;
                mz_adcLtc2311_hw_write_adc_available(self->config.base_address, adc_available);

                // Disable manual mode
                return_value = mz_adcLtc2311_disable_manual_mode(self->config.base_address, self->config.max_attempts);
                if (return_value == MZ_FAILURE)
                {
                    self->config.error_code |= MZ_ADCLTC2311_NS_MAN_MODE_DIS_FAILED;
                }
            }
        }
    }
    return (return_value);
}

void mz_adcLtc2311_set_channel_config(mz_adcLtc2311_t *self, uint32_t master_select, uint32_t channel_select, struct mz_adcLtc2311_channel_config_t channel_config)
{
    mz_assert_not_NULL(self);
    mz_adcLtc2311_set_conversion_factor(self, channel_config.conversion_factor, channel_config.conversion_factor_definition);
    mz_adcLtc2311_set_offset(self, channel_config.offset);
    mz_adcLtc2311_set_master_select(self, master_select);
    mz_adcLtc2311_set_channel_select(self, channel_select);
    mz_adcLtc2311_update_conversion_factor(self);
    mz_adcLtc2311_update_offset(self);
}

void mz_adcLtc2311_change_trigger_mode(mz_adcLtc2311_t *self, enum mz_adcLtc2311_trigger_mode trigger_mode){
    mz_assert_not_NULL(self);
    self->config.spi_master_config.trigger_mode=trigger_mode;
    mz_adcLtc2311_set_trigger_mode(self);
}

void mz_adcLtc2311_set_trigger_mode(mz_adcLtc2311_t *self)
{
    mz_assert_not_NULL(self);
    switch (self->config.spi_master_config.trigger_mode)
    {
    case pl_trigger:
        mz_adcLtc2311_set_triggered_mode(self);
        mz_adcLtc2311_set_pl_trigger_mode(self);
        break;
    case software_trigger:
        mz_adcLtc2311_set_triggered_mode(self);
        mz_adcLtc2311_set_software_trigger_mode(self);
        break;
    case continuous_trigger:
        mz_adcLtc2311_set_continuous_mode(self);
        break;
    default:
        break;
    }
}

#endif
