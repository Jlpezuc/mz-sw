#ifndef MZ_GPIO_H
#define MZ_GPIO_H

#include <stdbool.h>
#include "xgpiops.h"

typedef struct mz_gpio_ {
	XGpioPs *hw;
	_Bool is_ready;
	int pin_number;
	int direction;
} mz_gpio;

void mz_gpio_init(mz_gpio *self, XGpioPs *Xgpio_instance, uint32_t pin_number, uint32_t direction);

void mz_gpio_set_direction(struct mz_gpio_ *self, uint32_t Direction);
uint32_t mz_gpio_get_direction(struct mz_gpio_ *self);
void mz_gpio_set_enable_output(struct mz_gpio_ *self, uint32_t EnableOutput);
uint32_t mz_gpio_get_enable_output(struct mz_gpio_ *self);
void mz_gpio_write_pin(struct mz_gpio_ *self, uint32_t value);
uint32_t mz_gpio_read_pin(struct mz_gpio_ *self);


#endif
