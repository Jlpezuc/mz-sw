#include "mz_LED_facade.h"

static mz_statusLED readyLED;
static mz_statusLED runningLED;
static mz_statusLED errorLED;
static mz_statusLED userLED;

void mz_led_facade_init(mz_LedfacadeCfg cfg) {
	mz_led_init(&readyLED, cfg.LedReady);
	mz_led_init(&runningLED, cfg.LedRunning);
	mz_led_init(&errorLED, cfg.LedError);
	mz_led_init(&userLED, cfg.LedUser);
}

void mz_led_set_readyLED_on() {
	mz_led_turn_on(&readyLED);
}

void mz_led_set_readyLED_off() {
	mz_led_turn_off(&readyLED);
}

void mz_led_set_runningLED_on() {
	mz_led_turn_on(&runningLED);
}

void mz_led_set_runningLED_off() {
	mz_led_turn_off(&runningLED);
}

void mz_led_set_errorLED_on() {
	mz_led_turn_on(&errorLED);
}

void mz_led_set_errorLED_off() {
	mz_led_turn_off(&errorLED);
}

void mz_led_set_userLED_on() {
	mz_led_turn_on(&userLED);
}

void mz_led_set_userLED_off() {
	mz_led_turn_off(&userLED);
}
