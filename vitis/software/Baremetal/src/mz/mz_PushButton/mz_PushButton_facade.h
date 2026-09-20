// Facade for LEDs of the microzohm
// provides API for LEDs
#ifndef MZ_PUSHBUTTON_FACADE_H
#define MZ_PUSHBUTTON_FACADE_H

#include "../mz_HAL.h"
#include "../mz_GPIO/mz_gpio.h"
#include "mz_PushButton.h"
#include "stdbool.h"

typedef struct{
	mz_gpio *EnableSystem;
	mz_gpio *EnableControl;
	mz_gpio *Stop;
}mz_PushButtonFacadeCfg;

void mz_PushButton_facade_init(mz_PushButtonFacadeCfg cfg);

_Bool mz_GetPushButtonStop();
_Bool mz_GetPushButtonEnableSystem();
_Bool mz_GetPushButtonEnableControl();

#endif
