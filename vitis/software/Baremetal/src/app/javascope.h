/******************************************************************************
* Copyright 2021 Eyke Liegmann, Sebastian Wendel, Philipp Löhdefink, Michael Hoerner
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

#ifndef INCLUDE_JAVASCOPE_H_
#define INCLUDE_JAVASCOPE_H_

#include "APU_RPU_shared.h"
#include "../globalData.h"   // MZ_SCOPE_SIGNALS

// Senales fijas del sistema (ADC de A1/A2 y tiempos del ISR): X(nombre, puntero al float).
// Las senales de la aplicacion se definen en globalData.h (MZ_SCOPE_SIGNALS, Global_Data.sv) y se anaden solas.
#define MZ_SCOPE_SYSTEM_SIGNALS(X) \
	X(A1_1, &data->aa.A1.me.ADC_A1) X(A1_2, &data->aa.A1.me.ADC_A2) X(A1_3, &data->aa.A1.me.ADC_A3) X(A1_4, &data->aa.A1.me.ADC_A4) \
	X(A1_5, &data->aa.A1.me.ADC_B5) X(A1_6, &data->aa.A1.me.ADC_B6) X(A1_7, &data->aa.A1.me.ADC_B7) X(A1_8, &data->aa.A1.me.ADC_B8) \
	X(A2_1, &data->aa.A2.me.ADC_A1) X(A2_2, &data->aa.A2.me.ADC_A2) X(A2_3, &data->aa.A2.me.ADC_A3) X(A2_4, &data->aa.A2.me.ADC_A4) \
	X(A2_5, &data->aa.A2.me.ADC_B5) X(A2_6, &data->aa.A2.me.ADC_B6) X(A2_7, &data->aa.A2.me.ADC_B7) X(A2_8, &data->aa.A2.me.ADC_B8) \
	X(ISR_ExecTime_us, &ISR_execution_time_us) X(ISR_Period_us, &ISR_period_us) X(lifecheck, &lifecheck)

// Senales seleccionables en los canales del scope. El indice del enum es el valor que envia la GUI.
// Do not change the first (zero) and last (end) entries.
enum JS_OberservableData {
	JSO_ZEROVALUE=0,
#define X(name, ...) JSO_##name,
	MZ_SCOPE_SIGNALS(X)
	MZ_SCOPE_SYSTEM_SIGNALS(X)
#undef X
	JSO_ENDMARKER
};

// Datos lentos: se envia UNO por interrupcion, de forma rotatoria (ver js_slowDataArray en javascope.c).
// Prefijo JSSD_FLOAT_. mzscope los muestra todos en la tabla "Datos lentos"; los que llevan un
// comentario /* etiqueta [unidad] */ aparecen ademas en el panel de lecturas con ese texto.
// Do not change the first (zero) and last (end) entries.
enum JS_SlowData {
	JSSD_ZEROVALUE=0,
	JSSD_FLOAT_SecondsSinceSystemStart,  /* Tiempo de sistema [s] */
	JSSD_FLOAT_ISR_ExecTime_us,          /* Duracion del ISR [us] */
	JSSD_FLOAT_ISR_Period_us,            /* Periodo del ISR [us] */
	JSSD_FLOAT_Milliseconds,
	JSSD_ENDMARKER
};

// Comandos de la GUI (mzscope). El indice del enum es el id que envia la GUI junto con un valor float;
// ipc_ARM.c los atiende en ipc_Control_func (switch sobre estos nombres).
//   - Los cuatro primeros son fijos (maquina de estados) y no se tocan.
//   - Despues, cualquier cantidad de botones My_Button_n: mzscope crea un boton por linea con el texto
//     del comentario /* texto */ y un indicador que refleja el bit (4 + n - 1) de js_status_BareToRTOS.
//   - Despues, cualquier cantidad de campos Set_Send_Field_n: mzscope crea un campo numerico por linea
//     con la etiqueta y la unidad del comentario /* variable [unidad] */ y envia el valor escrito.
// Para anadir o quitar un boton/campo: la linea aqui y su case en ipc_ARM.c. Recargar en mzscope.
// Do not change the first (zero) and last (end) entries.
enum gui_button_mapping {
	GUI_BTN_ZEROVALUE=0,

	Enable_System,
	Enable_Control,
	Stop,
	Error_Reset,

	My_Button_1,        /* ON */
	My_Button_2,        /* OFF */

	Set_Send_Field_1,   /* Duty [V] */
	Set_Send_Field_2,   /* Frecuencia [Hz] */
	
	GUI_BTN_ENDMARKER
};

int JavaScope_initalize(DS_Data* data);
void JavaScope_update(DS_Data* data);

#endif /* INCLUDE_JAVASCOPE_H_ */
