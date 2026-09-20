#pragma once
#ifndef TEST

// Hardware version of the MicroZohm
//#define MZ_HARDWARE_VERSION 4U
#define HARDWARE_VERSION 0030010100U 



// Las frecuencias de la interrupcion de control y de muestreo de los ADC se fijan en
// el bloque "PARAMETROS DE ARRANQUE" de main.c (MZ_ISR_FREQUENCY_HZ, MZ_ADC_SAMPLE_FREQUENCY_HZ);
// el ISR lee la frecuencia real con mz_interruptClock_get_isr_frequency_Hz().


// Configuration defines for the number of used instances
#define MZ_ADCLTC2311_MAX_INSTANCES                     3U
#define MZ_PI_CONTROLLER_MAX_INSTANCES                  3U
#define MZ_CURRENTCONTROL_MAX_INSTANCES                 2U
#define MZ_IIR_FILTER_MAX_INSTANCES                     1U
#define MZ_ADCMAX11331_MAX_INSTANCES					1U
#endif

// Configuration defines for the number of used instances for testing with ceedling
#ifdef TEST
    #define MZ_ADCLTC2311_MAX_INSTANCES                     50U
    #define MZ_PI_CONTROLLER_MAX_INSTANCES                  100U
    #define MZ_CURRENTCONTROL_MAX_INSTANCES                 100U
    #define MZ_FILTER_1ST_ORDER_INSTANCES                   20U
    #define MZ_IIR_FILTER_MAX_INSTANCES                     20U
#endif
