/******************************************************************************
 * Copyright 2021 Eyke Liegmann, Tobias Schindler, Sebastian Wendel
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 ******************************************************************************/

/******************************************************************************
 * main.c - arranque del software del R5 (Baremetal) del MicroZohm
 *
 * Secuencia de inicializacion (enum init_chain):
 *   1. init_platform   : aserciones, GPIO de habilitacion (CPLD y DataMover a 0), LEDs y botones
 *   2. init_software   : tiempo de sistema y JavaScope/mzscope
 *   3. init_ip_cores   : ADC A1/A2/A3, reloj de la interrupcion, muestreo (trigger + promediador), DataMover
 *   4. init_interrupts : resumen por UART y arranque de la interrupcion de control (ISR_Control, isr.c)
 *   5. infinite_loop   : maquina de estados del MicroZohm (idle / running / control / error)
 *
 * Los parametros de todo esto estan en el bloque "PARAMETROS DE ARRANQUE" de abajo.
 ******************************************************************************/

#include "main.h"

//==============================================================================================================================================================
// PARAMETROS DE ARRANQUE (editar aqui)
//==============================================================================================================================================================

// ---- Reloj de la PL --------------------------------------------------------------------------------
#define MZ_PL_CLOCK_HZ                 100000000.0f   // pl_clk0: reloj de los IP cores y entrada del Clocking Wizard

// ---- Interrupcion de control (mz_system/interrupt_clock = Clocking Wizard + MZ_CLOCK_DIV) ----------
//   f_isr = f_base / N. La base f_base (salida del Clocking Wizard, 6.25 .. 775 MHz) la elige
//   mz_interruptClock a partir de f_isr y de las muestras del ADC por periodo: tiene que ser
//   f_isr * 2k * muestras para que el divisor del trigger del ADC (N / muestras) sea un entero par.
//   De las bases validas se toma la que el MMCM genera con menos error y, a igual error, la mas
//   cercana a MZ_INTERRUPT_CLOCK_PREFERRED_HZ. El UART muestra la base y las frecuencias reales.
#define MZ_ISR_FREQUENCY_HZ            10000.0f       // frecuencia de la interrupcion de control
#define MZ_INTERRUPT_CLOCK_PREFERRED_HZ 100000000.0f  // base preferida (solo desempata entre bases validas)

// ---- Muestreo de los ADC rapidos A1/A2 (LTC2311) ---------------------------------------------------
//   Muestras por periodo de la interrupcion. El trigger del ADC es f_base / MAX (mz_adcSampleClock)
//   y el promediador de A1 promedia estas muestras en cada periodo (mz_averager), asi el ISR lee
//   la media de las muestras del periodo anterior. Restricciones del hardware:
//     - potencia de 2 (1, 2, 4, ... 256): el promediador redondea hacia abajo a 2^k y su maximo
//       es 2**MAX_AVG_LOG2 del bloque (MZ_AVERAGER_MAX_SAMPLES);
//     - la base de la interrupcion se elige para que N / muestras sea un entero par (ver arriba);
//       main.c avisa por UART si aun asi no es exacto;
//     - f_adc = f_isr * muestras <= ~2 MHz (por encima el LTC2311 ignora triggers).
//   Con 1 muestra el ADC muestrea en el mismo flanco de la interrupcion y no se promedia.
#define MZ_ADC_SAMPLES_PER_ISR         64U
#define MZ_AVERAGER_MAX_SAMPLES        256U            // 2**MAX_AVG_LOG2 del bloque averager (mzsys.tcl)

// ---- Factores de conversion de los ADC (valor fisico = cuentas / 2^bits * factor) -------------------
//   A1/A2: 16 bit con signo -> factor = rango pico a pico (10.0 = +/- 5 V). A3: 12 bit.
#define MZ_ADC_A1_CONVERSION_FACTOR    10.0f
#define MZ_ADC_A2_CONVERSION_FACTOR    10.0f
#define MZ_ADC_A3_CONVERSION_FACTOR    5.0f

// ---- Valores iniciales de las variables de control (Global_Data.cv, las cambia la GUI) ------------
#define MZ_CV_ON_INIT                  false
#define MZ_CV_DUTY_INIT                0.5f
#define MZ_CV_FRECUENCIA_INIT          85000.0f

// ---- Direcciones base de los IP cores usados en el arranque (xparameters.h) ------------------------
#define MZ_ADDR_CLK_WIZ                XPAR_MZ_SYSTEM_INTERRUPT_CLOCK_CLK_WIZ_0_BASEADDR
#define MZ_ADDR_CLOCK_DIV              XPAR_MZ_SYSTEM_INTERRUPT_CLOCK_CLOCK_DIV_0_BASEADDR
#define MZ_ADDR_ADC_SAMPLE_CLOCK       XPAR_MZ_ANALOG_ADAPTER_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR
#define MZ_ADDR_AVERAGER               XPAR_MZ_ANALOG_ADAPTER_A1_ADAPTER_AXI_GPIO_0_BASEADDR

//==============================================================================================================================================================
// DATOS GLOBALES
//==============================================================================================================================================================

// Estructura global: variables de la aplicacion (av), senales del scope (sv, lista MZ_SCOPE_SIGNALS),
// variables de control que escribe la GUI (cv) y medidas de los ADC (aa). Ver globalData.h.
// El periodo real del ISR: mz_interruptClock_get_isr_frequency_Hz().
#define MZ_SAME_8(x)  {x, x, x, x, x, x, x, x}
#define MZ_SAME_16(x) {x, x, x, x, x, x, x, x, x, x, x, x, x, x, x, x}
DS_Data Global_Data = {
    .cv = {.on = MZ_CV_ON_INIT, .duty = MZ_CV_DUTY_INIT, .frecuencia = MZ_CV_FRECUENCIA_INIT},
    .aa = {
        .A1 = {.cf = {.ADC_array = MZ_SAME_8(MZ_ADC_A1_CONVERSION_FACTOR)}},
        .A2 = {.cf = {.ADC_array = MZ_SAME_8(MZ_ADC_A2_CONVERSION_FACTOR)}},
        .A3 = {.cf = {.ADC_array = MZ_SAME_16(MZ_ADC_A3_CONVERSION_FACTOR)}}
    }
};

// Ajuste real del reloj de la interrupcion (frecuencias obtenidas, parametros del MMCM y divisor)
static struct mz_interruptClock_setting_t irq_clock;
// Muestras reales por periodo del ISR: del trigger del ADC (entero si es exacto) y del promediador
static float adc_samples_per_isr = 0.0f;
static uint32_t averager_samples = 0U;

enum init_chain
{
    init_platform = 0,
    init_software,
    init_ip_cores,
    init_interrupts,
    infinite_loop
};
static enum init_chain initialization_chain = init_platform;

//==============================================================================================================================================================
// FUNCIONES DE INICIALIZACION (una por estado)
//==============================================================================================================================================================

/**
 * @brief Base de la plataforma. El orden es obligatorio: el callback de las aserciones usa el
 *        AXI GPIO para deshabilitar el sistema y los LEDs para indicar el error.
 *        Deja el CPLD y el DataMover deshabilitados (bits a 0).
 */
static void mz_init_platform(void)
{
    mz_assert_configuration();           // 1. callback de las aserciones (Xil_Assert)
    mz_axigpio_init();                   // 2. GPIO de habilitacion: CPLD bloqueado, DataMover parado
    mz_frontplane_button_and_led_init(); // 3. LEDs y botones del panel frontal (MIO)
}

/**
 * @brief Modulos de software que no dependen de la PL: tiempo de sistema y el scope.
 */
static void mz_init_software(void)
{
    mz_SystemTime_init();
    JavaScope_initalize(&Global_Data);
}

/**
 * @brief Programa el reloj de la interrupcion de control: Clocking Wizard (f_base) + MZ_CLOCK_DIV (N).
 *        La base se elige en funcion de MZ_ISR_FREQUENCY_HZ y MZ_ADC_SAMPLES_PER_ISR.
 *        Guarda en irq_clock las frecuencias reales obtenidas.
 */
static void mz_init_interrupt_clock(void)
{
    struct mz_interruptClock_config_t config = {
        .base_address_clk_wiz   = MZ_ADDR_CLK_WIZ,
        .base_address_clock_div = MZ_ADDR_CLOCK_DIV,
        .input_frequency_Hz     = MZ_PL_CLOCK_HZ};
    mz_interruptClock_init(config);
    float base_Hz = mz_interruptClock_choose_base_frequency(MZ_ISR_FREQUENCY_HZ, MZ_ADC_SAMPLES_PER_ISR, MZ_INTERRUPT_CLOCK_PREFERRED_HZ);
    irq_clock = mz_interruptClock_set_frequency(base_Hz, MZ_ISR_FREQUENCY_HZ);
}

/**
 * @brief Muestreo de los ADC A1/A2: MZ_ADC_SAMPLES_PER_ISR muestras por periodo de la interrupcion.
 *        1. trigger del ADC: divisor MAX = N / muestras del reloj base REAL (mz_adcSampleClock)
 *        2. promediador de A1: promedia esas muestras en cada periodo (mz_averager). El IP recarga el
 *           numero de muestras solo tras ver la interrupcion y una muestra con los canales
 *           deshabilitados, por eso va despues del trigger y con la interrupcion ya generandose.
 *        Llamar despues de mz_init_interrupt_clock (necesita irq_clock).
 */
static void mz_init_adc_sampling(void)
{
    mz_assert((MZ_ADC_SAMPLES_PER_ISR & (MZ_ADC_SAMPLES_PER_ISR - 1U)) == 0U); // potencia de 2

    struct mz_adcSampleClock_config_t clock_config = {
        .base_address      = MZ_ADDR_ADC_SAMPLE_CLOCK,
        .base_frequency_Hz = irq_clock.base_frequency_Hz};
    mz_adcSampleClock_init(clock_config);
    adc_samples_per_isr = mz_adcSampleClock_set_samples_per_isr(irq_clock.divider, MZ_ADC_SAMPLES_PER_ISR);

    struct mz_averager_config_t averager_config = {
        .base_address     = MZ_ADDR_AVERAGER,
        .max_samples      = MZ_AVERAGER_MAX_SAMPLES,
        .isr_frequency_Hz = irq_clock.isr_frequency_Hz};   // la recarga del IP espera periodos del ISR
    mz_averager_init(averager_config);
    averager_samples = mz_averager_set_samples(MZ_ADC_SAMPLES_PER_ISR);
}

/**
 * @brief IP cores de la PL: configuracion de los ADC, reloj de la interrupcion, frecuencia de
 *        muestreo y arranque del DataMover (a partir de aqui la TCM recibe los valores de los ADC).
 */
static void mz_init_ip_cores(void)
{
    mz_adcLtc2311_ip_core_init();   // A1 y A2 (app/mz_adcLtc2311_ip_core_init.c)
    mz_adcMax11331_ip_core_init();  // A3 (app/mz_adcMax11331_ip_core_init.c)
    mz_init_interrupt_clock();
    mz_init_adc_sampling();
    mz_axigpio_enable_datamover();
}

/**
 * @brief Resumen del arranque por UART: frecuencias reales de la interrupcion y del muestreo.
 */
static void mz_print_startup_summary(void)
{
    uint32_t adc_divider = mz_adcSampleClock_get_divider();
    mz_printf("\r\n\r\n");
    mz_printf("Welcome to the MicroZohm\r\n");
    mz_printf("----------------------------------------\r\n");
    mz_printf("RPU Build Date: %s at %s\r\n", __DATE__, __TIME__);
    mz_printf("ISR clock:   %lu Hz = %lu Hz (MMCM D=%lu M=%lu/8 O=%lu/8) / %lu\r\n",
              (unsigned long)(irq_clock.isr_frequency_Hz + 0.5f), (unsigned long)(irq_clock.base_frequency_Hz + 0.5f),
              (unsigned long)irq_clock.divclk_divide, (unsigned long)irq_clock.clkfbout_mult8,
              (unsigned long)irq_clock.clkout_divide8, (unsigned long)irq_clock.divider);
    mz_printf("ADC trigger: %lu Hz / %lu = %lu Hz -> %lu muestras por periodo del ISR, promediador: %lu\r\n",
              (unsigned long)(irq_clock.base_frequency_Hz + 0.5f), (unsigned long)adc_divider,
              (unsigned long)(mz_adcSampleClock_get_frequency_Hz() + 0.5f),
              (unsigned long)(adc_samples_per_isr + 0.5f), (unsigned long)averager_samples);
    if ((irq_clock.divider % adc_divider) != 0U) {
        mz_printf("WARNING: N = %lu no es multiplo del divisor del ADC %lu: el muestreo no es exacto (elegir la base de la interrupcion)\r\n",
                  (unsigned long)irq_clock.divider, (unsigned long)adc_divider);
    }
    if (averager_samples != MZ_ADC_SAMPLES_PER_ISR) {
        mz_printf("WARNING: el promediador solo admite potencias de 2: promedia %lu de %lu muestras\r\n",
                  (unsigned long)averager_samples, (unsigned long)MZ_ADC_SAMPLES_PER_ISR);
    }
}

/**
 * @brief Arranca la interrupcion de control (GIC + IPI, isr.c). Ultima inicializacion antes del bucle.
 */
static void mz_init_interrupts(void)
{
    mz_print_startup_summary();
    Initialize_ISR();
}

//==============================================================================================================================================================
// MAIN
//==============================================================================================================================================================

int main(void)
{
    while (1)
    {
        switch (initialization_chain)
        {
        case init_platform:
            mz_init_platform();
            initialization_chain = init_software;
            break;
        case init_software:
            mz_init_software();
            initialization_chain = init_ip_cores;
            break;
        case init_ip_cores:
            mz_init_ip_cores();
            initialization_chain = init_interrupts;
            break;
        case init_interrupts:
            mz_init_interrupts();
            initialization_chain = infinite_loop;
            break;
        case infinite_loop:
            microzohm_state_machine_step();
            break;
        default:
            break;
        }
    }
    return MZ_SUCCESS;
}
