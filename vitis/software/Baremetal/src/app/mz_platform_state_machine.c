#include "mz_platform_state_machine.h"

#include "../mz/mz_global_configuration.h"
#include "../mz/mz_SystemTime/mz_SystemTime.h"
#include "../mz/mz_LED/mz_LED_facade.h"
#include "../mz/mz_PushButton/mz_PushButton_facade.h"
#include "gpio_axi.h"
#include "mz_assertion_configuration.h"
#include "../main.h"

typedef struct
{
	bool readyLED;
	bool runningLED;
	bool errorLED;
	bool userLED;
} mz_led_states_t;

typedef struct
{
    platform_state_t current_state;
    mz_led_states_t mz_led_states;
    bool event_handled;
    bool entry;
    bool enable_system;
    bool enable_control;
    bool stop_flag;
    bool error_flag;
} microzohm_state_t;

microzohm_state_t microzohm_state = {
    .current_state = idle_state,
    .event_handled = true,
    .entry = true};

// Global variable structure
extern DS_Data Global_Data;

static void poll_buttons(void);
static void microzohm_state_machine_switch_to_state(platform_state_t new_state);
static void microzohm_state_machine_event_handled(void);
static void ready_LED_blink_slow(void);
static void ready_LED_blink_fast(void);


static void idle_entry(void);
static void running_entry(void);
static void control_entry(void);
static void error_entry(void);
static void idle_during(void);
static void running_during(void);
static void control_during(void);
static void error_during(void);

void microzohm_state_machine_step(void)
{
    switch (microzohm_state.current_state)
    {
    case idle_state:
        idle_entry();
        idle_during();
        break;
    case running_state:
        running_entry();
        running_during();
        break;
    case control_state:
        control_entry();
        control_during();
        break;
    case error_state:
        error_entry();
        error_during();
        break;
    default:
        break;
    }
    poll_buttons();
}

bool microzohm_state_machine_is_control_state(void)
{
    return (microzohm_state.current_state == control_state);
}

bool microzohm_state_machine_get_enable_system(void)
{
    return microzohm_state.enable_system;
}

bool microzohm_state_machine_get_enable_control(void)
{
    return microzohm_state.enable_control;
}

void microzohm_state_machine_set_enable_system(bool enable_system)
{
    microzohm_state.enable_system = enable_system;
}

void microzohm_state_machine_set_enable_control(bool enable_control)
{
    microzohm_state.enable_control = enable_control;
}

void microzohm_state_machine_set_stop(bool stop)
{
    microzohm_state.stop_flag = stop;
}

void microzohm_state_machine_set_userLED(bool onoff)
{
	if(onoff==true) {
		mz_led_set_userLED_on();
		microzohm_state.mz_led_states.userLED = true;
	} else {
		mz_led_set_userLED_off();
		microzohm_state.mz_led_states.userLED = false;
	}
}

void microzohm_state_machine_set_error(bool error)
{
    // Prevent setting error state multiple times
    if (error & (!(microzohm_state.current_state == error_state)))
    {
        microzohm_state_machine_switch_to_state(error_state); // if the error is set to true, directly change the current state to error and skip everything in the state machine
    }
    microzohm_state.error_flag = error;
    microzohm_state_machine_step(); // If the error bit is changed, execute the state machine again to enter the error state
}

static void idle_entry(void)
{
    if (microzohm_state.entry)
    {
        mz_axigpio_disable_cpld();
        microzohm_state.enable_control = false; // Resets the flags
        microzohm_state.enable_system = false;
        microzohm_state.stop_flag = false;
        microzohm_state.error_flag = false;
        mz_led_set_errorLED_off();
        microzohm_state.mz_led_states.errorLED = false;
        mz_led_set_runningLED_off();
        microzohm_state.mz_led_states.runningLED = false;
        microzohm_state_machine_event_handled();
    }
}

static void running_entry(void)
{
    if (microzohm_state.entry)
    {
        mz_led_set_errorLED_off();
        microzohm_state.mz_led_states.errorLED = false;
        mz_led_set_runningLED_off();
        microzohm_state.mz_led_states.runningLED = false;
        mz_axigpio_enable_cpld();
        microzohm_state_machine_event_handled();
    }
}

static void control_entry(void)
{
    if (microzohm_state.entry)
    {
        mz_led_set_errorLED_off();
        microzohm_state.mz_led_states.errorLED = false;
        mz_led_set_runningLED_on();
        microzohm_state.mz_led_states.runningLED = true;
        microzohm_state_machine_event_handled();
    }
}

static void error_entry(void)
{
    if (microzohm_state.entry)
    {
        mz_axigpio_disable_cpld();
        mz_led_set_errorLED_on();
        microzohm_state.mz_led_states.errorLED = true;
        mz_led_set_runningLED_off();
        microzohm_state.mz_led_states.runningLED = false;
        mz_led_set_userLED_off();
        microzohm_state.mz_led_states.userLED = false;
        mz_led_set_readyLED_off();
        microzohm_state.mz_led_states.readyLED = false;
        microzohm_state_machine_event_handled();
    }
}

static void error_during(void)
{
    if (microzohm_state.stop_flag)
    {
        microzohm_state_machine_switch_to_state(idle_state);
    }
}

static void idle_during(void)
{
    ready_LED_blink_slow();

//	mz_led_set_readyLED_on();
//	mz_led_set_runningLED_on();
//	mz_led_set_errorLED_on();
//	mz_led_set_userLED_on();
	if (microzohm_state.enable_system & (!microzohm_state.error_flag) & (!microzohm_state.stop_flag))
    {
        microzohm_state_machine_switch_to_state(running_state);
    }
    if (microzohm_state.error_flag)
    {
        microzohm_state_machine_switch_to_state(error_state);
    }
}

static void running_during(void)
{
    ready_LED_blink_fast();
    if (microzohm_state.error_flag)
    {
        microzohm_state_machine_switch_to_state(error_state);
    }
    if (microzohm_state.stop_flag & (!microzohm_state.error_flag))
    {
        microzohm_state_machine_switch_to_state(idle_state);
    }
    if (microzohm_state.enable_control & (!microzohm_state.error_flag) & (!microzohm_state.stop_flag))
    {
        microzohm_state_machine_switch_to_state(control_state);
    }
}

static void control_during(void)
{
    ready_LED_blink_fast();
    if (microzohm_state.error_flag)
    {
        microzohm_state_machine_switch_to_state(error_state);
    }
    if (microzohm_state.stop_flag & (!microzohm_state.error_flag))
    {
        microzohm_state_machine_switch_to_state(idle_state);
    }
}

static void ready_LED_blink_fast(void)
{
    uint32_t uptime_ms = mz_SystemTime_GetUptimeInMs();
    if ((uptime_ms % 200) > 100)
    {
        mz_led_set_readyLED_on();
        microzohm_state.mz_led_states.readyLED = true;
    }
    else
    {
        mz_led_set_readyLED_off();
        microzohm_state.mz_led_states.readyLED = false;
    }
}

static void ready_LED_blink_slow(void)
{
    uint32_t uptime_sec = mz_SystemTime_GetUptimeInSec();
    if (uptime_sec % 2)
    {
        mz_led_set_readyLED_on();
        microzohm_state.mz_led_states.readyLED = true;
    }
    else
    {
        mz_led_set_readyLED_off();
        microzohm_state.mz_led_states.readyLED = false;
    }
}

void poll_buttons(void)
{
#ifndef HARDWARE_VERSION
#error Hardware version of the MicroZohm is not defined!
#else
#if (HARDWARE_VERSION > 2U) // in CarrierBoard_v2 there are no buttons, therefore they are not polled.
    microzohm_state.enable_system = mz_GetPushButtonEnableSystem();
    microzohm_state.enable_control = mz_GetPushButtonEnableControl();
    microzohm_state.stop_flag = (mz_GetPushButtonStop()); // If 0, stop is pressed
#endif
#if (HARDWARE_VERSION == 2U) // in CarrierBoard_v2 there are no buttons, therefore they are not polled.
    microzohm_state.enable_system = 0;
    microzohm_state.enable_control = 0;
    microzohm_state.stop_flag = 0; // If 0, stop is pressed
#endif
#endif
}

static void microzohm_state_machine_event_handled(void)
{
    microzohm_state.event_handled = true;
    microzohm_state.entry = false;
}

static void microzohm_state_machine_switch_to_state(platform_state_t new_state)
{
    mz_assert(microzohm_state.event_handled);
    microzohm_state.event_handled = false;
    microzohm_state.entry = true;
    microzohm_state.current_state = new_state;
}

platform_state_t microzohm_state_machine_get_state(void)
{
    return (microzohm_state.current_state);
}

bool microzohm_state_get_led_running(void){
    return (microzohm_state.mz_led_states.runningLED);
}
bool microzohm_state_get_led_ready(void){
    return (microzohm_state.mz_led_states.readyLED);
}
bool microzohm_state_get_led_error(void){
    return (microzohm_state.mz_led_states.errorLED);
}
bool microzohm_state_get_led_user(void){
    return (microzohm_state.mz_led_states.userLED);
}
