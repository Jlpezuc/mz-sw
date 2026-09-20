/******************************************************************************
 * mz_adcSampleClock - driver del IP core MZ_CLOCK_FLAG_DIV (clock_flag_div_axi_mz_0)
 *
 * Genera el reloj de muestreo de los ADC rapidos A1/A2 (LTC2311): el IP divide el
 * reloj base de la interrupcion (mz_system/clk_base, salida del Clocking Wizard)
 * por un entero par MAX >= 2 y su salida clk_output es el trigger de conversion
 * TRIGGER_CNV de ambos ADC.
 *
 *   f_adc = f_base / MAX
 *
 * Como la interrupcion es f_isr = f_base / N (mz_interruptClock), cada periodo
 * del ISR contiene exactamente N / MAX muestras del ADC. El divisor arranca
 * sincronizado con el primer flanco de la interrupcion.
 *
 * Uso (en main.c, despues de mz_interruptClock_set_frequency):
 *   struct mz_adcSampleClock_config_t cfg = {
 *       .base_address      = XPAR_MZ_ANALOG_ADAPTER_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR,
 *       .base_frequency_Hz = irq_clock.base_frequency_Hz };
 *   mz_adcSampleClock_init(cfg);
 *   // a) muestras por periodo del ISR (exacto si N / muestras es un entero par):
 *   float n_real = mz_adcSampleClock_set_samples_per_isr(irq_clock.divider, 16U);
 *   // b) o directamente una frecuencia de muestreo:
 *   float f_real = mz_adcSampleClock_set_frequency(1.0e6f);
 *
 * Registros del IP (AXI4-Lite): 0x00 divisor MAX, 0x04 bit 0 reset / bit 1 enable.
 * El divisor solo se carga con el IP parado (enable = 0).
 ******************************************************************************/
#ifndef MZ_ADCSAMPLECLOCK_H
#define MZ_ADCSAMPLECLOCK_H

#include <stdint.h>
#include <stdbool.h>

/** Configuracion del modulo */
struct mz_adcSampleClock_config_t {
    uint32_t base_address;    /**< XPAR_..._CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR */
    float base_frequency_Hz;  /**< frecuencia REAL del reloj que se divide (irq_clock.base_frequency_Hz) */
};

/**
 * @brief Guarda la configuracion (direccion base y frecuencia del reloj base) y para el divisor.
 *        Hay que llamarla una vez antes de mz_adcSampleClock_set_frequency.
 */
void mz_adcSampleClock_init(struct mz_adcSampleClock_config_t config);

/**
 * @brief Programa la frecuencia de muestreo de los ADC A1/A2.
 *        Calcula el divisor par mas cercano a f_base / sample_frequency_Hz (minimo 2),
 *        lo carga con el IP parado y vuelve a arrancarlo.
 * @param sample_frequency_Hz frecuencia de muestreo deseada (por encima de ~2 MHz el
 *        LTC2311 ignora triggers mientras convierte y muestrea a su maximo).
 * @return frecuencia de muestreo REAL obtenida (f_base / divisor)
 */
float mz_adcSampleClock_set_frequency(float sample_frequency_Hz);

/**
 * @brief Programa el trigger para obtener un numero de muestras por periodo del ISR:
 *        divisor MAX = isr_divider / samples_per_isr (redondeado al par mas cercano, minimo 2).
 *        Es exacto cuando isr_divider / samples_per_isr es un entero par; si no, el numero real
 *        de muestras por periodo no es entero y el trigger deriva respecto a la interrupcion.
 * @param isr_divider     divisor N de la interrupcion (irq_clock.divider de mz_interruptClock)
 * @param samples_per_isr muestras deseadas por periodo del ISR (>= 1)
 * @return muestras REALES por periodo del ISR = isr_divider / MAX (entero si es exacto)
 */
float mz_adcSampleClock_set_samples_per_isr(uint32_t isr_divider, uint32_t samples_per_isr);

/** @brief Frecuencia de muestreo real programada (0 si esta parado). */
float mz_adcSampleClock_get_frequency_Hz(void);

/** @brief Divisor MAX que esta programado en el IP (leido del registro). */
uint32_t mz_adcSampleClock_get_divider(void);

/** @brief Para el trigger de los ADC (enable = 0). */
void mz_adcSampleClock_stop(void);

#endif // MZ_ADCSAMPLECLOCK_H
