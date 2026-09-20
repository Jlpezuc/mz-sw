#include "mz_PushButton.h"
#include "../mz_HAL.h"

void mz_PushBotton_init(mz_PushButton *self, mz_gpio *hw){
	mz_assert_not_NULL(self);
	self->isReady=true;
	self->hw=hw;
}

_Bool mz_PushButton_GetValue(mz_PushButton *self){
	mz_assert_not_NULL(self);
	mz_assert(self->isReady);
	return ((_Bool) mz_gpio_read_pin(self->hw));
}
