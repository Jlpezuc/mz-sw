/******************************************************************************
 * mz_averager - driver del IP core MZ_AVERAGER_8CH (mz_analog_adapter/A1_adapter/averager_mz_8ch_0)
 *
 * El promediador acumula n muestras de cada uno de los 8 canales del ADC de A1
 * y entrega la media al DataMover. Cada ventana se reinicia con el flanco de la
 * interrupcion de control, de modo que el ISR lee el promedio del periodo anterior.
 *
 * No tiene interfaz AXI propia: se configura con el AXI GPIO de dos canales
 * axi_gpio_0 de A1_adapter:
 *   canal 1 (offset 0x0): mascara de habilitacion de los 8 canales (bit i = canal i)
 *   canal 2 (offset 0x8): numero de muestras a promediar
 *
 * Limitaciones del hardware:
 *   - el numero de muestras se redondea HACIA ABAJO a una potencia de 2 (1, 2, 4, ...)
 *     y se limita a 2**MAX_AVG_LOG2 (256 en mzsys);
 *   - el numero de muestras solo se carga al (re)habilitar un canal, y el IP necesita
 *     ver, con el canal deshabilitado, un flanco de la interrupcion y una muestra del ADC
 *     antes de aceptar el valor nuevo (1..2 periodos del ISR). mz_averager_set_samples
 *     escribe el numero, deshabilita, espera 3 periodos del ISR y vuelve a habilitar;
 *     por eso hay que llamarla con la interrupcion y el trigger del ADC ya en marcha;
 *   - con 1 muestra (o canal deshabilitado) el dato pasa sin promediar.
 *
 * Uso (en main.c):
 *   struct mz_averager_config_t cfg = {
 *       .base_address     = XPAR_MZ_ANALOG_ADAPTER_A1_ADAPTER_AXI_GPIO_0_BASEADDR,
 *       .max_samples      = 256U,
 *       .isr_frequency_Hz = irq_clock.isr_frequency_Hz };
 *   mz_averager_init(cfg);
 *   uint32_t n_real = mz_averager_set_samples(100);   // -> 64
 ******************************************************************************/
#ifndef MZ_AVERAGER_H
#define MZ_AVERAGER_H

#include <stdint.h>
#include <stdbool.h>

/** Configuracion del modulo */
struct mz_averager_config_t {
    uint32_t base_address;  /**< XPAR_..._A1_ADAPTER_AXI_GPIO_0_BASEADDR */
    uint32_t max_samples;   /**< 2**MAX_AVG_LOG2 del bloque (256 en mzsys) */
    float isr_frequency_Hz; /**< frecuencia REAL de la interrupcion (para la espera de recarga) */
};

/**
 * @brief Guarda la configuracion y deshabilita el promedio de todos los canales
 *        (los datos pasan crudos). Llamar una vez antes de mz_averager_set_samples.
 */
void mz_averager_init(struct mz_averager_config_t config);

/**
 * @brief Programa el numero de muestras a promediar por periodo del ISR y habilita
 *        los 8 canales. El hardware redondea hacia abajo a una potencia de 2.
 *        Bloquea ~3 periodos del ISR (recarga del IP, ver arriba); la interrupcion y el
 *        trigger del ADC tienen que estar funcionando.
 * @param samples muestras deseadas (1 .. max_samples)
 * @return numero de muestras REAL que promedia el hardware (potencia de 2 <= samples)
 */
uint32_t mz_averager_set_samples(uint32_t samples);

/** @brief Numero de muestras real programado (0 si el promedio esta deshabilitado). */
uint32_t mz_averager_get_samples(void);

/** @brief Deshabilita el promedio de todos los canales (pasan los datos crudos). */
void mz_averager_disable(void);

#endif // MZ_AVERAGER_H
