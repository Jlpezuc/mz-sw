/******************************************************************************
 * Copyright 2021 Sebastian Wendel, Philipp Löhdefink
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
 **************************************************************************************************************************************************
 * ipc_ARM.c - comandos que llegan de la GUI (mzscope -> A53 -> buzon IPI -> R5)
 *
 * JavaScope_update (javascope.c) lee el buzon en cada interrupcion y llama a
 * ipc_Control_func(id, value, &Global_Data). El id es el indice del enum
 * gui_button_mapping (javascope.h): estados de la maquina de estados, seleccion
 * de canales del scope, botones de usuario (My_Button_n) y consignas
 * (Set_Send_Field_n). Los botones y las consignas escriben en Global_Data.cv
 * (ControlValues, globalData.h), que es lo que consulta el ISR.
 *
 * Al final se rellena js_status_BareToRTOS, que vuelve a la GUI en cada paquete:
 *   bits 0..3  LEDs ready / running / error / user
 *   bit 4+n-1  indicador del boton My_Button_n
 ******************************************************************************/
#include <string.h>
#include "../main.h"
#include "ipc_ARM.h"
#include "mz_platform_state_machine.h"
#include <stdbool.h>

extern float *js_ch_observable[JSO_ENDMARKER];
extern float *js_ch_selected[JS_CHANNELS];
extern uint32_t js_status_BareToRTOS;

// Seleccion de canal del scope: ids 201..220 (SELECT_DATA_CHn), value = indice de JS_OberservableData
#define IPC_SELECT_CHANNEL_FIRST 201U
#define IPC_SELECT_CHANNEL_LAST  (IPC_SELECT_CHANNEL_FIRST + JS_CHANNELS - 1U)

static void set_status_bit(uint32_t bit, bool value)
{
	if (value) {
		js_status_BareToRTOS |= (1U << bit);
	} else {
		js_status_BareToRTOS &= ~(1U << bit);
	}
}

void ipc_Control_func(uint32_t msgId, float value, DS_Data *data)
{
	// ---- seleccion de canales del scope -------------------------------------------------------
	if (msgId >= IPC_SELECT_CHANNEL_FIRST && msgId <= IPC_SELECT_CHANNEL_LAST) {
		if (value >= 0.0f && value < (float)JSO_ENDMARKER) {
			js_ch_selected[msgId - IPC_SELECT_CHANNEL_FIRST] = js_ch_observable[(uint32_t)value];
		}
	}
	// ---- comandos de la GUI (enum gui_button_mapping) -----------------------------------------
	else if (msgId != 0U) {
		switch (msgId) {
		// maquina de estados
		case Enable_System:
			microzohm_state_machine_set_enable_system(true);
			break;
		case Enable_Control:
			microzohm_state_machine_set_enable_control(true);
			break;
		case Stop:
			microzohm_state_machine_set_stop(true);
			break;
		case Error_Reset:
			microzohm_state_machine_set_stop(true);   // error -> idle (mismo camino que Stop)
			break;

		// botones de usuario -> Global_Data.cv
		case My_Button_1:                              /* ON */
			data->cv.on = true;
			microzohm_state_machine_set_userLED(true);
			break;
		case My_Button_2:                              /* OFF */
			data->cv.on = false;
			microzohm_state_machine_set_userLED(false);
			break;

		// consignas -> Global_Data.cv
		case Set_Send_Field_1:                         /* duty [-] */
			data->cv.duty = value;
			break;
		case Set_Send_Field_2:                         /* frecuencia [Hz] */
			data->cv.frecuencia = value;
			break;

		case 0xFFFFU:
			// buzon IPI leido sin que el A53 haya escrito nunca (arranque)
			break;
		default:
			// la GUI envia tambien ids que aqui no se usan: se ignoran
			break;
		}
	}

	// ---- realimentacion hacia la GUI (js_status_BareToRTOS) -----------------------------------
	set_status_bit(0U, microzohm_state_get_led_ready());
	set_status_bit(1U, microzohm_state_get_led_running());
	set_status_bit(2U, microzohm_state_get_led_error());
	set_status_bit(3U, microzohm_state_get_led_user());
	set_status_bit(4U, data->cv.on);                   // indicador de My_Button_1 (ON)
	set_status_bit(5U, !data->cv.on);                  // indicador de My_Button_2 (OFF)
}
