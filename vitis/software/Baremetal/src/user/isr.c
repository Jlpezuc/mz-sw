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
 * isr.c - interrupcion de control del MicroZohm
 *
 * ISR_Control se ejecuta a MZ_ISR_FREQUENCY_HZ (main.c), disparada por la PL
 * (mz_system/interrupt_clock -> pl_ps_irq0[0]). Estructura de cada periodo:
 *
 *   1. mz_SystemTime_ISR_Tic()          medida del tiempo de ejecucion (primera linea)
 *   2. ADC_readCardALL(&Global_Data)    lee los 32 valores de los ADC (TCM, DataMover)
 *                                       -> Global_Data.aa.A1/A2/A3.me.*
 *   3. bloque de control                solo en el estado "control" de la maquina
 *                                       de estados (Enable System + Enable Control en mzscope)
 *   4. JavaScope_update(&Global_Data)   envia al scope las senales de Global_Data.sv
 *                                       y lee los comandos de la GUI (ipc_ARM.c -> Global_Data.cv)
 *   5. mz_SystemTime_ISR_Toc()          (ultima linea)
 *
 * Datos disponibles dentro del ISR (globalData.h):
 *   Global_Data.aa   medidas de los ADC (ya escaladas con los factores de main.c)
 *   Global_Data.cv   consignas de la GUI (botones y campos), p. ej. cv.on, cv.duty, cv.frecuencia
 *   Global_Data.av   variables globales de la aplicacion
 *   Global_Data.sv   senales del scope: todo lo que se escriba aqui se puede ver en mzscope
 *
 * Acceso a los IP cores de la PL: Xil_In32/Xil_Out32(XPAR_<instancia>_BASEADDR + offset)
 * (xparameters.h), o los drivers de IP_Cores/.
 *
 * El resto del fichero (Initialize_ISR, Rpu_GicInit, Rpu_IpiInit) configura el
 * controlador de interrupciones y el IPI con el A53; normalmente no hay que tocarlo.
 ******************************************************************************/

#include "isr.h"
#include "../defines.h"
#include "../main.h"
#include "../app/javascope.h"
#include "../app/adc.h"
#include "../app/mz_platform_state_machine.h"
#include "../mz/mz_SystemTime/mz_SystemTime.h"

// ---- user includes ---------------------------------------------------------------------------------


// Controlador de interrupciones (GIC) e IPI: una unica instancia de cada uno para todo el R5
XScuGic INTCInst;
XIpiPsu INTCInst_IPI;

// Estructura global (main.c)
extern DS_Data Global_Data;

// ---- variables de la aplicacion --------------------------------------------------------------------


//==============================================================================================================================================================
// INTERRUPCION DE CONTROL
//==============================================================================================================================================================
void ISR_Control(void *data)
{
    mz_SystemTime_ISR_Tic();            // tiene que ser la primera linea
    ADC_readCardALL(&Global_Data);      // medidas -> Global_Data.aa

    platform_state_t current_state = microzohm_state_machine_get_state();

    if (current_state == control_state)
    {
        // ---- control: se ejecuta solo con el sistema habilitado (estado "control") -----------------


        // ---- senales al scope (Global_Data.sv.<nombre> = ...) --------------------------------------
        Global_Data.sv.Magnitud = Global_Data.aa.A1.me.ADC_A1;
    }
    else
    {
        // ---- sistema deshabilitado (idle / running / error): salidas a valores seguros -------------

    }

    JavaScope_update(&Global_Data);     // scope y comandos de la GUI
    mz_SystemTime_ISR_Toc();            // tiene que ser la ultima linea
}

//==============================================================================================================================================================
// INICIALIZACION DE LAS INTERRUPCIONES (la llama main.c como ultimo paso del arranque)
//==============================================================================================================================================================
int Initialize_ISR(void)
{
    int status = Rpu_IpiInit(INTERRUPT_ID_IPI);       // buzon IPI con el A53 (scope / GUI)
    if (status != XST_SUCCESS)
    {
        xil_printf("RPU: Error: IPI initialization failed\r\n");
        return XST_FAILURE;
    }
    status = Rpu_GicInit(&INTCInst, INTERRUPT_ID_SCUG);   // GIC: conecta y habilita ISR_Control
    if (status != XST_SUCCESS)
    {
        xil_printf("RPU: Error: GIC initialization failed\r\n");
        return XST_FAILURE;
    }
    return status;
}

/**
 * @brief Inicializa el GIC del R5, registra el handler de excepciones, configura la interrupcion
 *        de la PL (Interrupt_ISR_ID) como flanco de subida, la conecta a ISR_Control y la habilita.
 */
int Rpu_GicInit(XScuGic *IntcInstPtr, u16 DeviceId)
{
    XScuGic_Config *IntcConfig = XScuGic_LookupConfig(DeviceId);
    int status = XScuGic_CfgInitialize(IntcInstPtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, IntcInstPtr);
    Xil_ExceptionEnable();

    // Prioridad 0 (maxima), disparo por flanco de subida (0b11); nivel alto seria 0b01
    XScuGic_SetPriorityTriggerType(IntcInstPtr, Interrupt_ISR_ID, 0x0, 0b11);

    status = XScuGic_Connect(IntcInstPtr, Interrupt_ISR_ID, (Xil_ExceptionHandler)ISR_Control, (void *)IntcInstPtr);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    XScuGic_Enable(IntcInstPtr, Interrupt_ISR_ID);

    xil_printf("RPU: Rpu_GicInit: Done\r\n");
    return XST_SUCCESS;
}

/**
 * @brief Inicializa el driver del IPI (buzon R5 <-> A53) que usa javascope.c para enviar los datos
 *        del scope y recibir los comandos de la GUI.
 */
u32 Rpu_IpiInit(u16 DeviceId)
{
    XIpiPsu_Config *IntcConfig_IPI = XIpiPsu_LookupConfig(DeviceId);
    if (IntcConfig_IPI == NULL)
    {
        xil_printf("RPU: Error: Ipi Init failed\r\n");
        return XST_FAILURE;
    }
    int status = XIpiPsu_CfgInitialize(&INTCInst_IPI, IntcConfig_IPI, IntcConfig_IPI->BaseAddress);
    if (status != XST_SUCCESS)
    {
        xil_printf("RPU: Error: IPI Config failed\r\n");
        return XST_FAILURE;
    }
    XIpiPsu_InterruptEnable(&INTCInst_IPI, XPAR_XIPIPS_TARGET_PSU_CORTEXR5_0_CH0_MASK);

    xil_printf("RPU: RPU_IpiInit: Done\r\n");
    return XST_SUCCESS;
}
