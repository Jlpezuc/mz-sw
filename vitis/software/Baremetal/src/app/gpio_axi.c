/******************************************************************************
* Copyright 2021 Sebastian Wendel, Eyke Liegmann, Tobias Schindler
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
#include "../mz/mz_HAL.h"
#include "gpio_axi.h"
#include "xgpio.h"

// AXI GPIO mz_system/mz_enable/axi_gpio_2 (ver gpio_axi.h para el significado de los bits).
// XGpio_Initialize recibe el DEVICE_ID (indice en la tabla del driver), NO la direccion base:
// con la BASEADDR (0x800F0000) se truncaba a 0 y se inicializaba el GPIO del promediador (A1).
#define GPIO_out_ID XPAR_MZ_SYSTEM_MZ_ENABLE_AXI_GPIO_2_DEVICE_ID

#define AXI_GPIO_CHANNEL 1

#define AXI_GPIO_CPLD_ENABLE    (1U << 1) // bit 1 -> ENABLE_CPLD_HIGH
#define AXI_GPIO_AXI2TCM_ENABLE (1U << 4) // bit 4 -> ENABLE_AXI2TCM

static XGpio Gpio_OUT; /* instancia del driver del AXI GPIO */

void mz_axigpio_init(void)
{
    int status = XGpio_Initialize(&Gpio_OUT, GPIO_out_ID);
    mz_assert(XST_SUCCESS == status);
    XGpio_SetDataDirection(&Gpio_OUT, AXI_GPIO_CHANNEL, 0x00U); // todos los bits son salidas
    XGpio_DiscreteWrite(&Gpio_OUT, AXI_GPIO_CHANNEL, 0x00U);    // todo deshabilitado
}

void mz_axigpio_enable_cpld(void)
{
    XGpio_DiscreteSet(&Gpio_OUT, AXI_GPIO_CHANNEL, AXI_GPIO_CPLD_ENABLE);
}

void mz_axigpio_disable_cpld(void)
{
    XGpio_DiscreteClear(&Gpio_OUT, AXI_GPIO_CHANNEL, AXI_GPIO_CPLD_ENABLE);
}

void mz_axigpio_enable_datamover(void)
{
    XGpio_DiscreteSet(&Gpio_OUT, AXI_GPIO_CHANNEL, AXI_GPIO_AXI2TCM_ENABLE);
}

void mz_axigpio_disable_datamover(void)
{
    XGpio_DiscreteClear(&Gpio_OUT, AXI_GPIO_CHANNEL, AXI_GPIO_AXI2TCM_ENABLE);
}
