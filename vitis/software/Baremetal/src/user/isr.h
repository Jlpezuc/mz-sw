/******************************************************************************
* Copyright 2021 Eyke Liegmann, Tobias Schindler, Sebastian Wendel, Philipp Löhdefink
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

#ifndef ISR_H_
#define ISR_H_

#include "../main.h"

// Interrupcion PL->PS unica del block design "mzsys" (vivado):
//   mz_system/interrupt_clock (Clocking Wizard + MZ_CLOCK_DIV) -> pl_ps_irq0[0] -> XPS_FPGA0_INT_ID
// La frecuencia del ISR la fija main.c con mz_interruptClock (f_base / N = MZ_ISR_FREQUENCY_HZ).
#define Interrupt_ISR_ID			XPS_FPGA0_INT_ID

void ISR_Control(void *data);                       // interrupcion de control (ver isr.c)
int Initialize_ISR(void);                           // GIC + IPI, ultimo paso del arranque (main.c)
int Rpu_GicInit(XScuGic *IntcInstPtr, u16 DeviceId);
u32 Rpu_IpiInit(u16 DeviceId);

#endif /* ISR_H_ */
