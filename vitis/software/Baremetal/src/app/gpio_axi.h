/******************************************************************************
* Copyright 2021 Sebastian Wendel, Tobias Schindler
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
 * gpio_axi - GPIO de habilitacion del block design (mz_system/mz_enable, AXI GPIO)
 *
 * Bits de salida (ver vivado/bd/mzsys.tcl, jerarquia mz_system/mz_enable):
 *   bit 1  ENABLE_CPLD_HIGH : patron de habilitacion del Safety CPLD (D*_OUT_28/29).
 *                             Con el bit a 0 el CPLD bloquea las salidas digitales
 *                             hacia los gate drivers. La maquina de estados lo pone
 *                             a 1 en los estados running/control y a 0 en idle/error.
 *   bit 4  ENABLE_AXI2TCM   : arranca el DataMover (copia de los 32 valores de los
 *                             ADC a la TCM del R5) y el enable_measure del MAX11331 (A3).
 ******************************************************************************/
#ifndef GPIO_AXI_H_
#define GPIO_AXI_H_

/**
 * @brief Inicializa el AXI GPIO de habilitacion con todas las salidas a 0
 *        (CPLD bloqueado, DataMover parado). Tiene que ser la primera
 *        inicializacion de hardware de main.c: el callback de las aserciones
 *        lo usa para deshabilitar el sistema.
 */
void mz_axigpio_init(void);

/** @brief Habilita el Safety CPLD (bit 1): las salidas digitales llegan a los gate drivers. */
void mz_axigpio_enable_cpld(void);

/** @brief Deshabilita el Safety CPLD (bit 1): las salidas digitales quedan bloqueadas. */
void mz_axigpio_disable_cpld(void);

/** @brief Arranca el DataMover (bit 4): a partir de aqui la TCM recibe los valores de los ADC. */
void mz_axigpio_enable_datamover(void);

/** @brief Para el DataMover (bit 4). */
void mz_axigpio_disable_datamover(void);

#endif /* GPIO_AXI_H_ */
