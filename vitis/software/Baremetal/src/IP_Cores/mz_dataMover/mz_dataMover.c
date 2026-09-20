/******************************************************************************
* Copyright Contributors to the MicroZohm project.
* Copyright 2021 Tobias Schindler
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

#include <stdbool.h>
#include <string.h> // for memcpy
#include "../../mz/mz_HAL.h"
#include "mz_dataMover.h" 
#define MZ_DATAMOVER_ARRAY_LENGTH 32 // Number of variables that are written to TCM by the dataMover

// Number of elements in one array
#define R5_0_BTCM_SPLIT_REG	0x20000U // Start of BTCM
static int16_t buffer[MZ_DATAMOVER_ARRAY_LENGTH]={0};

// Tested the following:
// volatile int16_t *ptr_to_btcm=(volatile int16_t *)(0x20000);
// And the version without volatile below with -O2 and there is not difference
// memcpy and the mz_array.data throw a warning that the volatile keyword is lost
// Since I am not sure how far the volatile keyword should be "propagated upwards"
// The version without is used - not sure about it
// cppcheck-suppress misra-c2012-11.4 // this is not allowed since there is no way to know that ptr_to_btcm actually points to int16_t variables - this can only be known be knowing the Vivado project
static int16_t *ptr_to_btcm=(int16_t *)(R5_0_BTCM_SPLIT_REG);

mz_array_int16_t mz_dataMover_get_data_by_pointer(void){
    mz_array_int16_t data_array={
        .length=MZ_ARRAY_SIZE(buffer),
        .data=ptr_to_btcm
    };
    return data_array;
}

mz_array_int16_t mz_dataMover_update_buffer_and_get_data(void){
    mz_dataMover_update_buffer();
    return (mz_dataMover_get_data_from_buffer());
}

void mz_dataMover_update_buffer(void){
    void *ptr_res=memcpy(&buffer, ptr_to_btcm,sizeof(buffer) );
    mz_assert_not_NULL(ptr_res); // checks return value of memcpy to make sure something happend
}

mz_array_int16_t mz_dataMover_get_data_from_buffer(void){
    mz_array_int16_t data_array={
        .length=MZ_ARRAY_SIZE(buffer),
        .data=&buffer[0]
    };
    return data_array;
}
