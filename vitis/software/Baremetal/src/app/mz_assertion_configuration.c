#include <stdbool.h>
#include "xil_assert.h"

#include "../mz/mz_HAL.h"
#include "mz_platform_state_machine.h"



static void mz_assertCallback(const char8 *file, s32 line);


void mz_assert_configuration(void){
    Xil_AssertSetCallback((Xil_AssertCallback)mz_assertCallback);
}

static void mz_assertCallback(const char8 *file, s32 line)
{
    mz_printf("\r\n RPU: Assertion in file %s on line %d\r\n", file, line);
    microzohm_state_machine_set_error(true);
}
