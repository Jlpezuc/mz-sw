#ifndef MZ_LED_H
#define MZ_LED_H

#include <stdbool.h>
#include "../mz_GPIO/mz_gpio.h"

typedef struct mz_Statusled_{
	_Bool is_ready;
	mz_gpio *hw;
}mz_statusLED;

void mz_led_init(mz_statusLED *self, mz_gpio *hw);

void mz_led_turn_on(mz_statusLED *self);
void mz_led_turn_off(mz_statusLED *self);

#endif
