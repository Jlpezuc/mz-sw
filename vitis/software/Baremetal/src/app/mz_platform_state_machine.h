#pragma once
#include <stdbool.h>

/**
 * @brief Enum for the available states of the MicroZohm
 * 
 */
typedef enum
{
    idle_state = 0, // _state is used here to prevent name duplication with the flags
    running_state,
    control_state,
    error_state
} platform_state_t;


/**
 * @brief Returns the current state of the microzohm
 * 
 * @return platform_state_t 
 */
platform_state_t microzohm_state_machine_get_state(void);

/**
 * @brief Exectures the central state machine of the MicroZohm once
 * 
 */
void microzohm_state_machine_step(void);

/**
 * @brief Sets the input signal enable system of the state machine
 * 
 * @param enable_system 
 */
void microzohm_state_machine_set_enable_system(bool enable_system);

/**
 * @brief Sets the input signal enable control of the state machine
 * 
 * @param enable_control 
 */
void microzohm_state_machine_set_enable_control(bool enable_control);

/**
 * @brief Sets the input signal stop of the state machine
 * 
 * @param stop 
 */
void microzohm_state_machine_set_stop(bool stop);

/**
 * @brief Sets the user LED
 *
 * @param onoff
 */
void microzohm_state_machine_set_userLED(bool onoff);

/**
 * @brief Sets the input signal error of the state machine
 * 
 * @param error 
 */
void microzohm_state_machine_set_error(bool error);

/**
 * @brief Get state of the input signal enable system
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_machine_get_enable_system(void);

/**
 * @brief Get state of the input signal enable control
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_machine_get_enable_control(void);

/**
 * @brief Special function to check if the state machine is in the state "control" - should only be used in the ISR!
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_machine_is_control_state(void);

/**
 * @brief Returns the current state of the running led
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_get_led_running(void);

/**
 * @brief Returns the current state of the ready led
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_get_led_ready(void);

/**
 * @brief Returns the current state of the error led
 * 
 * @return true 
 * @return false 
 */
bool microzohm_state_get_led_error(void);

/**
 * @brief Returns the current state of the user led
 *
 * @return true
 * @return false
 */
bool microzohm_state_get_led_user(void);
