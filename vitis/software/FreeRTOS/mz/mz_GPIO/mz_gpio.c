#include "mz_gpio.h"

#include "../mz_HAL.h"

void mz_gpio_init(mz_gpio *self, XGpioPs *Xgpio_instance, uint32_t pin_number, uint32_t direction) {
	mz_assert_not_NULL(self);
	mz_assert_not_NULL(Xgpio_instance);
	mz_assert(Xgpio_instance->IsReady);
	self->hw = Xgpio_instance;
	self->pin_number = pin_number;
	self->direction = direction;
	self->is_ready = true;
	mz_gpio_set_direction(self, self->direction);
}

void mz_gpio_set_direction(struct mz_gpio_ *self, uint32_t Direction) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	self->direction=Direction;
	XGpioPs_SetDirectionPin(self->hw, (uint32_t) self->pin_number, (uint32_t) self->direction);
}

uint32_t mz_gpio_get_direction(struct mz_gpio_ *self) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	return ((uint32_t) XGpioPs_GetDirectionPin(self->hw, (uint32_t) self->pin_number));
}

void mz_gpio_set_enable_output(struct mz_gpio_ *self, uint32_t EnableOutput) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	XGpioPs_SetOutputEnablePin(self->hw, (uint32_t) self->pin_number, (uint32_t) EnableOutput);
}

uint32_t mz_gpio_get_enable_output(struct mz_gpio_ *self) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	return ((uint32_t) XGpioPs_GetOutputEnablePin(self->hw, (uint32_t) self->pin_number));
}

void mz_gpio_write_pin(struct mz_gpio_ *self, uint32_t value) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	mz_assert( mz_gpio_get_enable_output(self) );
	XGpioPs_WritePin(self->hw, (uint32_t) self->pin_number, (uint32_t) value);
}

uint32_t mz_gpio_read_pin(struct mz_gpio_ *self) {
	mz_assert_not_NULL(self);
	mz_assert(self->is_ready);
	return (XGpioPs_ReadPin(self->hw, (uint32_t) self->pin_number));
}
