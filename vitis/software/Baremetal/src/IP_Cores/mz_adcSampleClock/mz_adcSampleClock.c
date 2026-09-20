/******************************************************************************
 * mz_adcSampleClock.c - ver mz_adcSampleClock.h
 ******************************************************************************/
#include "mz_adcSampleClock.h"
#include "../../mz/mz_HAL.h"
#include "xil_io.h"

// Registros de MZ_CLOCK_FLAG_DIV (ip_cores/MZ_CLOCK_FLAG_DIV_1.0)
#define CLOCK_FLAG_DIV_REG_DIVIDER   0x00U   // MAX (par, >= 2), se carga al arrancar
#define CLOCK_FLAG_DIV_REG_CONTROL   0x04U   // bit 0: reset, bit 1: enable
#define CLOCK_FLAG_DIV_ENABLE        0x2U
#define CLOCK_FLAG_DIV_STOP          0x0U
#define CLOCK_FLAG_DIV_MIN_DIVIDER   2U

static struct mz_adcSampleClock_config_t cfg;
static bool is_ready = false;
static float current_frequency_Hz = 0.0f;

void mz_adcSampleClock_init(struct mz_adcSampleClock_config_t config)
{
    mz_assert_not_zero(config.base_address);
    mz_assert(config.base_frequency_Hz > 0.0f);
    cfg = config;
    is_ready = true;
    mz_adcSampleClock_stop();
}

// Divisor par mas cercano a ratio (el IP hace MAX/2 con division entera: un impar se comporta como el par inferior)
static uint32_t even_divider(float ratio)
{
    uint32_t divider = (uint32_t)(ratio + 0.5f) & ~1U;
    if (divider < CLOCK_FLAG_DIV_MIN_DIVIDER) {
        divider = CLOCK_FLAG_DIV_MIN_DIVIDER;
    }
    return divider;
}

// El divisor solo se lee al arrancar: parar, escribir, arrancar.
// Al arrancar se sincroniza con el primer flanco de la interrupcion (clock_base_2sync = mz_system/irq).
static void load_divider(uint32_t divider)
{
    Xil_Out32(cfg.base_address + CLOCK_FLAG_DIV_REG_CONTROL, CLOCK_FLAG_DIV_STOP);
    Xil_Out32(cfg.base_address + CLOCK_FLAG_DIV_REG_DIVIDER, divider);
    Xil_Out32(cfg.base_address + CLOCK_FLAG_DIV_REG_CONTROL, CLOCK_FLAG_DIV_ENABLE);
    current_frequency_Hz = cfg.base_frequency_Hz / (float)divider;
}

float mz_adcSampleClock_set_frequency(float sample_frequency_Hz)
{
    mz_assert(is_ready);
    mz_assert(sample_frequency_Hz > 0.0f);
    load_divider(even_divider(cfg.base_frequency_Hz / sample_frequency_Hz));
    return current_frequency_Hz;
}

float mz_adcSampleClock_set_samples_per_isr(uint32_t isr_divider, uint32_t samples_per_isr)
{
    mz_assert(is_ready);
    mz_assert(isr_divider >= 1U);
    mz_assert(samples_per_isr >= 1U);
    uint32_t divider = even_divider((float)isr_divider / (float)samples_per_isr);
    load_divider(divider);
    return (float)isr_divider / (float)divider;
}

float mz_adcSampleClock_get_frequency_Hz(void)
{
    return current_frequency_Hz;
}

uint32_t mz_adcSampleClock_get_divider(void)
{
    mz_assert(is_ready);
    return Xil_In32(cfg.base_address + CLOCK_FLAG_DIV_REG_DIVIDER);
}

void mz_adcSampleClock_stop(void)
{
    mz_assert(is_ready);
    Xil_Out32(cfg.base_address + CLOCK_FLAG_DIV_REG_CONTROL, CLOCK_FLAG_DIV_STOP);
    current_frequency_Hz = 0.0f;
}
