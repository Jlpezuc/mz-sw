/******************************************************************************
 * mz_averager.c - ver mz_averager.h
 ******************************************************************************/
#include "mz_averager.h"
#include "../../mz/mz_HAL.h"
#include "xil_io.h"

// AXI GPIO de dos canales (xgpio): registros de datos
#define AVERAGER_REG_ENABLE    0x0U          // GPIO canal 1: mascara de habilitacion (bit i = canal i)
#define AVERAGER_REG_SAMPLES   0x8U          // GPIO canal 2: muestras a promediar
#define AVERAGER_ALL_CHANNELS  0xFFU         // 8 canales
#define AVERAGER_NO_CHANNELS   0x0U

static struct mz_averager_config_t cfg;
static bool is_ready = false;
static uint32_t current_samples = 0U;

// mayor potencia de 2 <= n (n >= 1), igual que hace el hardware
static uint32_t floor_pow2(uint32_t n)
{
    uint32_t p = 1U;
    while ((p << 1) <= n && (p << 1) != 0U) {
        p <<= 1;
    }
    return p;
}

void mz_averager_init(struct mz_averager_config_t config)
{
    mz_assert_not_zero(config.base_address);
    mz_assert_not_zero(config.max_samples);
    mz_assert(config.isr_frequency_Hz > 0.0f);
    cfg = config;
    is_ready = true;
    mz_averager_disable();
}

uint32_t mz_averager_set_samples(uint32_t samples)
{
    mz_assert(is_ready);
    mz_assert(samples >= 1U);
    mz_assert(samples <= cfg.max_samples);

    // El IP solo recarga el numero de muestras con el canal deshabilitado, y para ello tiene que ver
    // un flanco de la interrupcion seguido de una muestra del ADC (MZ_AVERAGER_8CH_CHANNEL.vhd):
    // escribir el valor, deshabilitar, esperar 3 periodos del ISR y volver a habilitar.
    Xil_Out32(cfg.base_address + AVERAGER_REG_SAMPLES, samples);
    Xil_Out32(cfg.base_address + AVERAGER_REG_ENABLE, AVERAGER_NO_CHANNELS);
    mz_sleep_useconds((uint32_t)(3.0e6f / cfg.isr_frequency_Hz) + 10U);
    Xil_Out32(cfg.base_address + AVERAGER_REG_ENABLE, AVERAGER_ALL_CHANNELS);

    current_samples = floor_pow2(samples);
    return current_samples;
}

uint32_t mz_averager_get_samples(void)
{
    return current_samples;
}

void mz_averager_disable(void)
{
    mz_assert(is_ready);
    Xil_Out32(cfg.base_address + AVERAGER_REG_ENABLE, AVERAGER_NO_CHANNELS);
    current_samples = 0U;
}
