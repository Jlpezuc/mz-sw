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

#include "adc.h"
#include "../IP_Cores/mz_dataMover/mz_dataMover.h"
#include "../mz/mz_HAL.h"

void ADC_readCardA1(DS_Data *data, mz_array_int16_t adc_data)
{
    // bitshift operation of -16 digits, because it is an 16-bit ADC, scaling the value to +/- 0.5
    // multiplying it afterwards with the conversion factor, which is the peak-to-peak into value
    // Conversion Factor is defined in main.c InitializeDataStructure
    data->aa.A1.me.ADC_array[0] = ((float)adc_data.data[0]) / (1 << Q16) * data->aa.A1.cf.ADC_A1;
    data->aa.A1.me.ADC_array[1] = ((float)adc_data.data[1]) / (1 << Q16) * data->aa.A1.cf.ADC_A2;
    data->aa.A1.me.ADC_array[2] = ((float)adc_data.data[2]) / (1 << Q16) * data->aa.A1.cf.ADC_A3;
    data->aa.A1.me.ADC_array[3] = ((float)adc_data.data[3]) / (1 << Q16) * data->aa.A1.cf.ADC_A4;
    data->aa.A1.me.ADC_array[4] = ((float)adc_data.data[4]) / (1 << Q16) * data->aa.A1.cf.ADC_B5;
    data->aa.A1.me.ADC_array[5] = ((float)adc_data.data[5]) / (1 << Q16) * data->aa.A1.cf.ADC_B6;
    data->aa.A1.me.ADC_array[6] = ((float)adc_data.data[6]) / (1 << Q16) * data->aa.A1.cf.ADC_B7;
    data->aa.A1.me.ADC_array[7] = ((float)adc_data.data[7]) / (1 << Q16) * data->aa.A1.cf.ADC_B8;
}

void ADC_readCardA2(DS_Data *data, mz_array_int16_t adc_data)
{
    data->aa.A2.me.ADC_array[0] = ((float)adc_data.data[8]) / (1 << Q16) * data->aa.A2.cf.ADC_A1;
    data->aa.A2.me.ADC_array[1] = ((float)adc_data.data[9]) / (1 << Q16) * data->aa.A2.cf.ADC_A2;
    data->aa.A2.me.ADC_array[2] = ((float)adc_data.data[10]) / (1 << Q16) * data->aa.A2.cf.ADC_A3;
    data->aa.A2.me.ADC_array[3] = ((float)adc_data.data[11]) / (1 << Q16) * data->aa.A2.cf.ADC_A4;
    data->aa.A2.me.ADC_array[4] = ((float)adc_data.data[12]) / (1 << Q16) * data->aa.A2.cf.ADC_B5;
    data->aa.A2.me.ADC_array[5] = ((float)adc_data.data[13]) / (1 << Q16) * data->aa.A2.cf.ADC_B6;
    data->aa.A2.me.ADC_array[6] = ((float)adc_data.data[14]) / (1 << Q16) * data->aa.A2.cf.ADC_B7;
    data->aa.A2.me.ADC_array[7] = ((float)adc_data.data[15]) / (1 << Q16) * data->aa.A2.cf.ADC_B8;
}

void ADC_readCardA3(DS_Data *data, mz_array_int16_t adc_data)
{
    data->aa.A3.me.ADC_array[0]  = ((float)adc_data.data[16]) / (1 << Q12) * data->aa.A3.cf.ADC_array[0];
    data->aa.A3.me.ADC_array[1]  = ((float)adc_data.data[17]) / (1 << Q12) * data->aa.A3.cf.ADC_array[1];
    data->aa.A3.me.ADC_array[2]  = ((float)adc_data.data[18]) / (1 << Q12) * data->aa.A3.cf.ADC_array[2];
    data->aa.A3.me.ADC_array[3]  = ((float)adc_data.data[19]) / (1 << Q12) * data->aa.A3.cf.ADC_array[3];
    data->aa.A3.me.ADC_array[4]  = ((float)adc_data.data[20]) / (1 << Q12) * data->aa.A3.cf.ADC_array[4];
    data->aa.A3.me.ADC_array[5]  = ((float)adc_data.data[21]) / (1 << Q12) * data->aa.A3.cf.ADC_array[5];
    data->aa.A3.me.ADC_array[6]  = ((float)adc_data.data[22]) / (1 << Q12) * data->aa.A3.cf.ADC_array[6];
    data->aa.A3.me.ADC_array[7]  = ((float)adc_data.data[23]) / (1 << Q12) * data->aa.A3.cf.ADC_array[7];
    data->aa.A3.me.ADC_array[8]  = ((float)adc_data.data[24]) / (1 << Q12) * data->aa.A3.cf.ADC_array[8];
    data->aa.A3.me.ADC_array[9]  = ((float)adc_data.data[25]) / (1 << Q12) * data->aa.A3.cf.ADC_array[9];
    data->aa.A3.me.ADC_array[10] = ((float)adc_data.data[26]) / (1 << Q12) * data->aa.A3.cf.ADC_array[10];
    data->aa.A3.me.ADC_array[11] = ((float)adc_data.data[27]) / (1 << Q12) * data->aa.A3.cf.ADC_array[11];
    data->aa.A3.me.ADC_array[12] = ((float)adc_data.data[28]) / (1 << Q12) * data->aa.A3.cf.ADC_array[12];
    data->aa.A3.me.ADC_array[13] = ((float)adc_data.data[29]) / (1 << Q12) * data->aa.A3.cf.ADC_array[13];
    data->aa.A3.me.ADC_array[14] = ((float)adc_data.data[30]) / (1 << Q12) * data->aa.A3.cf.ADC_array[14];
    data->aa.A3.me.ADC_array[15] = ((float)adc_data.data[31]) / (1 << Q12) * data->aa.A3.cf.ADC_array[15];
}

void ADC_readCardALL(DS_Data *data)
{
    mz_array_int16_t adc_data = mz_dataMover_update_buffer_and_get_data();
    ADC_readCardA1(data, adc_data);
    ADC_readCardA2(data, adc_data);
    ADC_readCardA3(data, adc_data);
}
