// Facade for LEDs of the microzohm
// provides API for LEDs
#ifndef MZ_LED_FACADE_H
#define MZ_LED_FACADE_H

#include "../mz_HAL.h"
#include "../mz_GPIO/mz_gpio.h"
#include "mz_LED.h"

typedef struct{
	mz_gpio *LedReady;
	mz_gpio *LedError;
	mz_gpio *LedRunning;
	mz_gpio *LedUser;
}mz_LedfacadeCfg;

void mz_led_facade_init(mz_LedfacadeCfg cfg);

void mz_led_set_readyLED_on();
void mz_led_set_readyLED_off();

void mz_led_set_runningLED_on();
void mz_led_set_runningLED_off();

void mz_led_set_errorLED_on();
void mz_led_set_errorLED_off();

void mz_led_set_userLED_on();
void mz_led_set_userLED_off();

#endif
