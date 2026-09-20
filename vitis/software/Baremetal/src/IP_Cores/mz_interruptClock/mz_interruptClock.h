/******************************************************************************
 * mz_interruptClock: reloj de la interrupcion del ISR (mz_system/interrupt_clock)
 *
 *   pl_clk0 (100 MHz) -> Clocking Wizard (frecuencia base f_base, por AXI)
 *                     -> MZ_CLOCK_DIV (divisor N >= 1, por AXI)  ->  f_isr = f_base / N
 *
 * La frecuencia base se elige libremente dentro de lo que permite el MMCM (con la
 * entrada de 100 MHz, aproximadamente 6.25 MHz .. 775 MHz, en pasos finos gracias a
 * los multiplicadores/divisores fraccionarios), y el divisor lleva la senal al rango
 * del ISR. Ejemplo: 85 kHz exactos = 102 MHz / 1200.
 ******************************************************************************/
#ifndef MZ_INTERRUPTCLOCK_H
#define MZ_INTERRUPTCLOCK_H

#include <stdint.h>
#include <stdbool.h>

struct mz_interruptClock_config_t {
    uint32_t base_address_clk_wiz;   /**< XPAR_..._CLK_WIZ_0_BASEADDR (Clocking Wizard, s_axi_lite) */
    uint32_t base_address_clock_div; /**< XPAR_..._CLOCK_DIV_0_BASEADDR (MZ_CLOCK_DIV) */
    float input_frequency_Hz;        /**< reloj de entrada del Clocking Wizard (pl_clk0, 100 MHz) */
};

/** Parametros del MMCM y del divisor calculados para una frecuencia. */
struct mz_interruptClock_setting_t {
    uint32_t divclk_divide;   /**< D  (1..106) */
    uint32_t clkfbout_mult8;  /**< M en octavos (16..1024 = 2.000..128.000) */
    uint32_t clkout_divide8;  /**< O en octavos (8..1024 = 1.000..128.000) */
    uint32_t divider;         /**< N del MZ_CLOCK_DIV (>= 1) */
    float base_frequency_Hz;  /**< f_base real = f_in * M / (D * O) */
    float isr_frequency_Hz;   /**< f_isr real = f_base / N */
};

/**
 * Inicializa el modulo (no toca el hardware). Llamar una vez antes de set_frequency.
 */
void mz_interruptClock_init(struct mz_interruptClock_config_t config);

/**
 * Programa la frecuencia base del Clocking Wizard y el divisor para obtener f_isr.
 *
 * Busca los parametros M/D/O del MMCM que mejor aproximan base_frequency_Hz y el
 * divisor entero que mejor aproxima isr_frequency_Hz a partir de la base real.
 * Espera al 'locked' del MMCM y arranca el divisor. El ISR (y el trigger de los ADC
 * sincronizado con el) empiezan a correr al volver de esta funcion.
 *
 * @param base_frequency_Hz  frecuencia deseada a la salida del Clocking Wizard (f_base)
 * @param isr_frequency_Hz   frecuencia deseada del ISR (f_base / N)
 * @return                   ajuste aplicado (frecuencias reales incluidas)
 */
struct mz_interruptClock_setting_t mz_interruptClock_set_frequency(float base_frequency_Hz, float isr_frequency_Hz);

/**
 * Solo calcula (sin tocar el hardware) el ajuste para una pareja de frecuencias.
 */
struct mz_interruptClock_setting_t mz_interruptClock_calculate(float input_frequency_Hz, float base_frequency_Hz, float isr_frequency_Hz);

/**
 * @brief Elige la frecuencia base a partir de la frecuencia del ISR y de las muestras del ADC por periodo.
 *        La base tiene que ser f_isr * N con N = 2k * samples_per_isr (el divisor del trigger del ADC,
 *        N / samples_per_isr, tiene que ser un entero par). De los multiplos de 2 * samples_per_isr * f_isr
 *        que caben en el rango del MMCM se elige el que el Clocking Wizard genera con menos error y, a
 *        igual error, el mas cercano a preferred_base_Hz.
 * @param isr_frequency_Hz  frecuencia deseada de la interrupcion
 * @param samples_per_isr   muestras del ADC por periodo del ISR (>= 1)
 * @param preferred_base_Hz base preferida (p. ej. 100 MHz); solo desempata
 * @return frecuencia base a pasar a mz_interruptClock_set_frequency
 */
float mz_interruptClock_choose_base_frequency(float isr_frequency_Hz, uint32_t samples_per_isr, float preferred_base_Hz);

/** Frecuencia real del ISR programada por la ultima llamada a set_frequency (0 si ninguna). */
float mz_interruptClock_get_isr_frequency_Hz(void);

/** true si el MMCM esta enganchado y el divisor en marcha. */
bool mz_interruptClock_is_running(void);

/** Para el divisor (deja de generarse la interrupcion). set_frequency lo vuelve a arrancar. */
void mz_interruptClock_stop(void);

#endif // MZ_INTERRUPTCLOCK_H
