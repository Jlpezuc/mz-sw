/******************************************************************************
* Copyright 2021 Sebastian Wendel, Eyke Liegmann
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

#include "xparameters.h"
#include "netif/xadapter.h"

#if LWIP_DHCP==1
#include "lwip/dhcp.h"
#endif

#include "../include/isr.h"
#include "../defines.h"
#include "APU_RPU_shared.h"
#include "xil_cache.h"

struct APU_to_RPU_t ControlData;
extern int js_connection_established;

#define input_size   5
#define layer1_size  15
#define output_size  11


// Total de variables = layer1 + output + (W1) + (W2) + (B1) + (B2)
#define N ( layer1_size \
          + output_size \
          + input_size*layer1_size \
          + layer1_size*output_size \
          + layer1_size \
          + output_size )

float Measures[N][10000];

int print_meas ;
int selector_print = 0 ;
int i_print = 0 ;

int Enable_Meas = 0 ;
int contador_medicion = 0 ;
int i_meas = 0 ;

int cant_variables_print = 40 ;
int size_data_print = 5000 ;

int new_data_from_R5= 0;

// cf. main.c
extern uint32_t javascope_data_status;

// Javascope Queue parameters
QueueHandle_t js_queue;
int js_queue_full = 0;

int i_LifeCheck_Transfer_ipc;

//Initialize the Interrupt structure
XScuGic INTCipc;	//Interrupt for IPC
XIpiPsu INTCInst_IPI;  	//Interrupt handler -> only instance one -> responsible for ALL interrupts of the IPI!
XScuGic_Config *IntcConfig;

/**
 * Apu_IpiHandler() - Interrupt handler for IPI
 *
 * @IpiInstPtr		Pointer to the IPI instance
 */
// Standard isr interrupt from BareMetal -> frequency depends on the Software-interrupt from BareMetal

//static struct Shared_Data volatile * const control_data1 = (struct Shared_Data*)MEM_SHARED_MID1;
//static struct Shared_Data volatile * const control_data2 = (struct Shared_Data*)MEM_SHARED_MID2;
//static struct Shared_Data volatile * const control_data3 = (struct Shared_Data*)MEM_SHARED_MID3;
//static struct Shared_Data volatile * const control_data4 = (struct Shared_Data*)MEM_SHARED_MID4;
//static struct Shared_Data volatile * const control_data5 = (struct Shared_Data*)MEM_SHARED_MID5;
//static struct Shared_Data volatile * const control_data6 = (struct Shared_Data*)MEM_SHARED_MID6;
//static struct Shared_Data volatile * const control_data7 = (struct Shared_Data*)MEM_SHARED_MID7;
void Transfer_ipc_Intr_Handler(void *data)
{
	// create pointer to javascope_data_t named javascope_data located at MEM_SHARED_START
	struct javascope_data_t volatile * const javascope_data = (struct javascope_data_t*)MEM_SHARED_START;



	int status;
	BaseType_t xHigherPriorityTaskWoken;

	// Escribir datos en la memoria compartida
	//control_data1->value[0] = variable;

	//Leer datos de la memoria compartida
	//variable = control_data1->value[0];

	//Datos control R5_to_A53
	//new_data_from_R5 = (int)(control_data7->value[0]);

	if (new_data_from_R5 == 1)
	{
		Enable_Meas = 1;
	}
	else
	{
		Enable_Meas = 0;
	}


	// flush cache of shared memory
	Xil_DCacheFlushRange( MEM_SHARED_START, JAVASCOPE_DATA_SIZE_2POW);

	//Xil_DCacheFlushRange( MEM_SHARED_MID1, sizeof(control_data1));
	//Xil_DCacheFlushRange( MEM_SHARED_MID2, sizeof(control_data2));
	//Xil_DCacheFlushRange( MEM_SHARED_MID3, sizeof(control_data3));
	//Xil_DCacheFlushRange( MEM_SHARED_MID4, sizeof(control_data4));
	//Xil_DCacheFlushRange( MEM_SHARED_MID5, sizeof(control_data5));
	//Xil_DCacheFlushRange( MEM_SHARED_MID6, sizeof(control_data6));
	Xil_DCacheFlushRange( MEM_SHARED_MID7, sizeof(struct Shared_Data));

	//Get_Data_Improved();
	//Print_Data();


	// if javascope connection is established
	if(js_connection_established!=0)
	{
		// append sample to queue
		size_t queue_status = xQueueSendToBackFromISR(js_queue, javascope_data, &xHigherPriorityTaskWoken);

		if (queue_status == errQUEUE_FULL)
		{
			js_queue_full++;
			// mz_printf("OsziData_queue is full\r\n");
		}
	}
	// queue is purged when new connection is established

	// Maintain APU-local copy of status word (cf. main.c)
	javascope_data_status = javascope_data->status;

	u32_t ControlData_length = sizeof(ControlData)/sizeof(float); // XIpiPsu_WriteMessage expects number of 32bit values as message length
	// Write message for acknowledge of the interrupt to RPU
	status = XIpiPsu_WriteMessage(&INTCInst_IPI, XPAR_XIPIPS_TARGET_PSU_CORTEXR5_0_CH0_MASK, (u32_t*)(&ControlData), ControlData_length, XIPIPSU_BUF_TYPE_RESP);

	// Valid IPI. Clear the appropriate bit in the respective ISR
	XIpiPsu_ClearInterruptStatus(&INTCInst_IPI, XPAR_XIPIPS_TARGET_PSU_CORTEXR5_0_CH0_MASK);

	i_LifeCheck_Transfer_ipc++;

	if(i_LifeCheck_Transfer_ipc > 25000){
		i_LifeCheck_Transfer_ipc =0;
	}

	// force context switch after ISR finishes -> switching to ethernet task
	portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}


//==============================================================================================================================================================
//----------------------------------------------------
// INITIALIZE THE INTERRUPT HAndler (from main)
//----------------------------------------------------
int Initialize_InterruptHandler(){

	int Status = XST_SUCCESS;

	// Interrupt controller configuration
	IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_0_DEVICE_ID);
		if(IntcConfig == NULL) {
			mz_printf("APU: Error: GIC Config failed\r\n");
			return XST_FAILURE;
		}

	// Interrupt controller initialization
	Status = XScuGic_CfgInitialize(&INTCipc, IntcConfig, IntcConfig->CpuBaseAddress);
		if(Status != XST_SUCCESS) {
			mz_printf("APU: Error: GIC initialization failed\r\n");
			return XST_FAILURE;
		}

	return Status;
}


//==============================================================================================================================================================
//----------------------------------------------------
// INITIALIZE & SET THE INTERRUPTs and ISRs
//----------------------------------------------------
int Initialize_ISR(){

	int Status = 0;

	// Initialize RPU GIC and Connect IPI interrupt
	Status = Apu_GicInit(&INTCipc, XPAR_XIPIPSU_0_INT_ID,(Xil_ExceptionHandler)Transfer_ipc_Intr_Handler, &INTCInst_IPI);
	if(Status != XST_SUCCESS) {
		mz_printf("APU: Error: GIC initialization failed\r\n");
		return XST_FAILURE;
	}

	// create queue for buffering R5 interrupt -> ethernet thread
	js_queue = xQueueCreate( JS_QUEUE_SIZE_ELEMENTS, sizeof(struct javascope_data_t) );
	if (js_queue == NULL){
		mz_printf("APU: Error: Queue creation failed\r\n");
		return XST_FAILURE;
	}

	// Initialize interrupt controller for the IPI -> Initialize RPU IPI
	Status = Apu_IpiInit(&INTCInst_IPI, INTERRUPT_ID_IPI);
	if(Status != XST_SUCCESS) {
		mz_printf("APU: Error: IPI initialization failed\r\n");
		return XST_FAILURE;
	}


	return Status;
}

//==============================================================================================================================================================
/**
 * Apu_GicInit() - This function initializes APU GIC and connects
 * 					interrupts with the associated handlers
 * @IntcInstPtr		Pointer to the GIC instance
 * @IntId			Interrupt ID to be connected and enabled
 * @Handler			Associated handler for the Interrupt ID
 * @PeriphInstPtr	Connected interrupt's Peripheral instance pointer
 */
u32 Apu_GicInit(XScuGic *IntcInstPtr, u32 IntId, Xil_ExceptionHandler Handler, void *PeriphInstPtr)
{
	u32 Status = XST_SUCCESS;

	// Connect the interrupt controller interrupt handler to the hardware interrupt handling logic in the processor
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,(Xil_ExceptionHandler)XScuGic_InterruptHandler,IntcInstPtr);
	Xil_ExceptionEnable();										//Enable interrupts in the ARM

	// Make the connection between the IntId of the interrupt source and the
	// associated handler that is to run when the interrupt is recognized.
	Status = XScuGic_Connect(IntcInstPtr, IntId, Handler, PeriphInstPtr);

	XScuGic_Enable(IntcInstPtr, IntId);

	//mz_printf("APU: Apu_GicInit: Done\r\n");
	return Status;
}


//==============================================================================================================================================================
/**
 * Apu_IpiInit() - This function initializes APU IPI and enables IPI interrupts
 *
 * @IpiInstPtr		Pointer to the IPI instance
 */
u32 Apu_IpiInit(XIpiPsu *IntcInst_IPI_Ptr,u16 DeviceId)
{
	XIpiPsu_Config *IntcConfig_IPI;
	int status;

	// Interrupt controller configuration
	IntcConfig_IPI = XIpiPsu_LookupConfig(DeviceId);
		if (IntcConfig_IPI == NULL) {
			mz_printf("APU: Error: Ipi Init failed\r\n");
			return XST_FAILURE;
		}

	// Interrupt controller initialization
	status = XIpiPsu_CfgInitialize(IntcInst_IPI_Ptr, IntcConfig_IPI, IntcConfig_IPI->BaseAddress);
		if (status != XST_SUCCESS) {
			mz_printf("APU: Error: IPI Config failed\r\n");
			return XST_FAILURE;
		}

	XIpiPsu_InterruptEnable(IntcInst_IPI_Ptr, XPAR_XIPIPS_TARGET_PSU_CORTEXR5_0_CH0_MASK);

	mz_printf("APU: APU_IpiInit: Done\r\n");
	return XST_SUCCESS;
}


void Print_Data(){
    if (print_meas==1) {
        if (selector_print < cant_variables_print) {
            if (selector_print==0 && i_print==0) {
                printf("Mediciones: \n");
            }

            // ------------ Medicion [selector_print] ------------
            if (i_print < size_data_print) {
                if (i_print==0) {
                    printf("M%i = [",selector_print);   // <----- M_i
                }

                printf("%f ", Measures[selector_print][i_print]); // <----- Measure_(i-1)
                i_print = i_print + 1;
            }
            else if (i_print == size_data_print) {
                printf("];\n");
                selector_print = selector_print + 1; // pasa a sig meas
                i_print = 0; // reinicia contador print
            }
        }
        else {
            print_meas = 0;
            i_print = 0;
        }
    }
}


//Obtener los datos:
/*
void Get_Data_Improved()
{
    if (Enable_Meas == 1) {
        contador_medicion++;
        if (contador_medicion >= 1) {   // puedes subir este >=1 a >=N para submuestreo

            int k = 0; // índice lineal en Measures

            // 1) out_layer1
            for (int i = 0; i < 8; i++) { //layer1_size
                out_layer1_host[i] = control_data1->value[i];
                Measures[k++][i_meas] = out_layer1_host[i];
            }

            // 2) output
            for (int i = 0; i < 8; i++) {//output_size
                output_host[i] = control_data2->value[i];
                Measures[k++][i_meas] = output_host[i];
            }

            // 3) W1
            int idx = 0;
            for (int i = 0; i < input_size; i++) {
                for (int j = 0; j < layer1_size; j++) {
                    W1_host[i][j] = control_data3->value[idx];
                    Measures[k++][i_meas] = W1_host[i][j];
                    idx++;
                }
            }

            // 4) W2
            idx = 0;
            for (int i = 0; i < layer1_size; i++) {
                for (int j = 0; j < output_size; j++) {
                    W2_host[i][j] = control_data4->value[idx];
                    Measures[k++][i_meas] = W2_host[i][j];
                    idx++;
                }
            }

            // 5) B1
            for (int i = 0; i < layer1_size; i++) {
                B1_host[i] = control_data5->value[i];
                Measures[k++][i_meas] = B1_host[i];
            }

            // 6) B2
            for (int i = 0; i < output_size; i++) {
                B2_host[i] = control_data6->value[i];
                Measures[k++][i_meas] = B2_host[i];
            }

            // Avanzar índice temporal
            i_meas++;
            if (i_meas == size_data_print) {
                i_meas = 0;
                Enable_Meas = 0;
                contador_medicion = 0;
                print_meas = 1;  // listo para imprimir
                //if (selector_print > 0) {
                //    selector_print = 0;
                //    i_print = 0;
               // }
            }
        }
    }
}*/



