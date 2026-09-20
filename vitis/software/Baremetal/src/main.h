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

#ifndef main_H_
#define main_H_

#include <math.h>										//Include for math operations
#include <stdbool.h>

// Xilinx library functions
#include "xscugic.h"									//Include for Interrupt handler (necessary for all GIC interrupts)
#include "xipipsu.h"									//Include for Interrupt handler (necessary for all IPI interrupts)
#include "xtmrctr.h"									//Include of the Timer-Blocks

#include "app/mz_platform_state_machine.h"
#include "mz/mz_global_configuration.h"
#include "app/mz_adcLtc2311_ip_core_init.h"
#include "app/mz_adcMax11331_ip_core_init.h"
#include "IP_Cores/mz_interruptClock/mz_interruptClock.h"
#include "IP_Cores/mz_adcSampleClock/mz_adcSampleClock.h"
#include "IP_Cores/mz_averager/mz_averager.h"
#include "app/mz_assertion_configuration.h"


// MicroZohm includes
#include "globalData.h"
#include "defines.h"
#include "user/isr.h"     // ISR de la aplicacion (carpeta del usuario)
#include "app/gpio_axi.h"
#include "app/javascope.h"

#include "mz/mz_HAL.h"

#include "mz/mz_LED/mz_LED_facade.h"
#include "mz/mz_PushButton/mz_PushButton_facade.h"

#include "mz/mz_MioGpio_mediator/mz_MioGpio_mediator.h"
#include "mz/mz_MioGpio_mediator/mz_MioGpioMapping.h"

#include "mz/mz_SystemTime/mz_SystemTime.h"

//User includes

#endif /* main_H_ */
