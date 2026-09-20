#include "mz_LED.h"
#include "../mz_HAL.h"


void mz_led_init(mz_statusLED *self, mz_gpio *hw){
	mz_assert_not_NULL(self);
	self->is_ready=true;
	self->hw=hw;
}

void mz_led_turn_on(mz_statusLED *self){
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	mz_gpio_write_pin(self->hw,true);
}

void mz_led_turn_off(mz_statusLED *self){
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	mz_gpio_write_pin(self->hw,false);
}
