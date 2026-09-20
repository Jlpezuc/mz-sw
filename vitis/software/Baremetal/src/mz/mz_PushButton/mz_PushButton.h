#ifndef MZ_PUSHBUTTON_H
#define MZ_PUSHBUTTON_H

#include <stdbool.h>
#include "../mz_GPIO/mz_gpio.h"

typedef struct mz_PushButton_{
	_Bool isReady;
	mz_gpio *hw;
}mz_PushButton;

void mz_PushBotton_init(mz_PushButton *self, mz_gpio *hw);
_Bool mz_PushButton_GetValue(mz_PushButton *self);

#endif
