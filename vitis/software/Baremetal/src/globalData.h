#ifndef GLOBAL_DATA_H
#define GLOBAL_DATA_H

#include <stdbool.h>
#include <stdint.h>

// union allows to access the values as array and individual variables
// see also this link for more information: https://hackaday.com/2018/03/02/unionize-your-variables-an-introduction-to-advanced-data-types-in-c/
typedef union _ConversionFactors1_ {
	struct{
		float ADC_A1;
		float ADC_A2;
		float ADC_A3;
		float ADC_A4;
		float ADC_B5;
		float ADC_B6;
		float ADC_B7;
		float ADC_B8;
		};
	float ADC_array[8];
} ConversionFactors1;

typedef union _ConversionFactors2_ {
	struct{
		float ADC_0;
		float ADC_1;
		float ADC_2;
		float ADC_3;
		float ADC_4;
		float ADC_5;
		float ADC_6;
		float ADC_7;
		float ADC_8;
		float ADC_9;
		float ADC_10;
		float ADC_11;
		float ADC_12;
		float ADC_13;
		float ADC_14;
		float ADC_15;
		};
	float ADC_array[16];
} ConversionFactors2;

typedef union _OffsetFactors1_ {
	struct{
		float ADC_A1;
		float ADC_A2;
		float ADC_A3;
		float ADC_A4;
		float ADC_B5;
		float ADC_B6;
		float ADC_B7;
		float ADC_B8;
		};
	float ADC_array[8];
} OffsetFactors1;

typedef union _OffsetFactors2_ {
	struct{
		float ADC_0;
		float ADC_1;
		float ADC_2;
		float ADC_3;
		float ADC_4;
		float ADC_5;
		float ADC_6;
		float ADC_7;
		float ADC_8;
		float ADC_9;
		float ADC_10;
		float ADC_11;
		float ADC_12;
		float ADC_13;
		float ADC_14;
		float ADC_15;
		};
	float ADC_array[16];
} OffsetFactors2;

typedef union _Measurements1_ {
	struct{
		float ADC_A1;
		float ADC_A2;
		float ADC_A3;
		float ADC_A4;
		float ADC_B5;
		float ADC_B6;
		float ADC_B7;
		float ADC_B8;
		};
	float ADC_array[8];
} Measurements1;

typedef union _Measurements2_ {
	struct{
		float ADC_0;
		float ADC_1;
		float ADC_2;
		float ADC_3;
		float ADC_4;
		float ADC_5;
		float ADC_6;
		float ADC_7;
		float ADC_8;
		float ADC_9;
		float ADC_10;
		float ADC_11;
		float ADC_12;
		float ADC_13;
		float ADC_14;
		float ADC_15;
		};
	float ADC_array[16];
} Measurements2;

typedef struct _ADCcard1_ {
	ConversionFactors1 	cf;
	OffsetFactors1 		of;
	Measurements1		me;
} ADCcard1;

typedef struct _ADCcard2_ {
	ConversionFactors2 	cf;
	OffsetFactors2 		of;
	Measurements2		me;
} ADCcard2;

typedef struct _AnalogAdapters_ {
	ADCcard1 A1;
	ADCcard1 A2;
	ADCcard2 A3;
} AnalogAdapters;

//==============================================================================================================================================================
// VARIABLES GLOBALES DE LA APLICACION (Global_Data.av)
//==============================================================================================================================================================
typedef struct _ActualValues_ {
	float Magnitud;
	float Fase;
	float Frecuencia;
	float Inductancia_Mutua;
	float Carga;
} ActualValues;

//==============================================================================================================================================================
// SENALES DEL SCOPE (Global_Data.sv)
//   Una linea por senal: X(nombre). Cada linea crea el campo float Global_Data.sv.<nombre> y lo
//   anade automaticamente a la lista de senales del scope (mzscope) con ese nombre, sin tocar
//   javascope.c/.h. Para anadir una senal: X(nombre) aqui y, en el ISR, Global_Data.sv.nombre = ...;
//   mzscope vuelve a leer esta lista al arrancar (globalData.h + app/javascope.h).
//==============================================================================================================================================================
#define MZ_SCOPE_SIGNALS(X) \
	X(Magnitud)             \
	X(Fase)                 \
	X(Frecuencia)           \
	X(Inductancia_Mutua)    \
	X(Carga)

typedef struct _ScopeValues_ {
#define X(name) float name;
	MZ_SCOPE_SIGNALS(X)
#undef X
} ScopeValues;

//==============================================================================================================================================================
// VARIABLES DE CONTROL DE LA APLICACION (Global_Data.cv)
//   Las escribe la GUI (mzscope) a traves de ipc_ARM.c: los botones My_Button_n y las consignas
//   Set_Send_Field_n del enum gui_button_mapping (app/javascope.h). Valores iniciales en main.c.
//==============================================================================================================================================================
typedef struct _ControlValues_ {
	bool  on;          // botones ON / OFF
	float duty;        // consigna 1
	float frecuencia;  // consigna 2 [Hz]
} ControlValues;


typedef struct _DS_Data_ {
	ActualValues av;	// variables globales de la aplicacion
	ScopeValues sv;		// senales que se envian al scope (lista MZ_SCOPE_SIGNALS)
	ControlValues cv;   // Variables de control, se usan para ser modificadas mediante el mzscope
	AnalogAdapters aa;	// medidas de los ADC A1/A2/A3
} DS_Data;

#endif

