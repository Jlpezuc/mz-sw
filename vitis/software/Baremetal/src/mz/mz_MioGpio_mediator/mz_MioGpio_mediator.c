#include "../mz_HAL.h"
#include "../mz_GPIO/mz_gpio.h"
#include "../mz_LED/mz_LED.h"
#include "../mz_LED/mz_LED_facade.h"

#include "../mz_PushButton/mz_PushButton.h"
#include "../mz_PushButton/mz_PushButton_facade.h"

#include "xgpiops.h"
#include "../mz_MioGpio_mediator/mz_MioGpioMapping.h"
#include "mz_MioGpio_mediator.h"

static void InitializeXilinxMioGpioInstance();
static void InitializeMioPinsForLEDs();
static void enableAllMioWithLEDsAttached();
static void InitializeAllStatusLEDs();
static void TurnAllLEDOff();
static void InitializeMioPinsForButtons();
static void InitializeAllPushButtons();
static void enableAllMioWithButonsAttached();

static XGpioPs Gpio_inst;
static mz_gpio MIO_LedReady;
static mz_gpio MIO_LedRunning;
static mz_gpio MIO_LedError;
static mz_gpio MIO_LedUser;
static mz_gpio MIO_SWError;
static mz_gpio MIO_SWControl;
static mz_gpio MIO_SWSystem;

void mz_frontplane_button_and_led_init() {
	InitializeXilinxMioGpioInstance();
	InitializeMioPinsForLEDs();
	enableAllMioWithLEDsAttached();
	InitializeAllStatusLEDs();
	TurnAllLEDOff();

	InitializeMioPinsForButtons();
	InitializeAllPushButtons();
	enableAllMioWithButonsAttached();
}

static void InitializeXilinxMioGpioInstance() {
	XGpioPs_Config gpio_config;
	gpio_config.BaseAddr = XPAR_PSU_GPIO_0_BASEADDR; // e.g.: XPAR_PSU_GPIO_0_BASEADDR;
	gpio_config.DeviceId = XPAR_PSU_GPIO_0_DEVICE_ID; // e.g.: XPAR_PSU_GPIO_0_DEVICE_ID;
	int status = XGpioPs_CfgInitialize(&Gpio_inst, &gpio_config, gpio_config.BaseAddr);
	mz_assert_false(status); // 0 -> no error 
}

static void InitializeMioPinsForLEDs() {
	mz_gpio_init(&MIO_LedReady, &Gpio_inst, LED_ready, OUTPUT_PIN);
	mz_gpio_init(&MIO_LedRunning, &Gpio_inst, LED_running, OUTPUT_PIN);
	mz_gpio_init(&MIO_LedError, &Gpio_inst, LED_error, OUTPUT_PIN);
	mz_gpio_init(&MIO_LedUser, &Gpio_inst, LED_user, OUTPUT_PIN);
}

static void InitializeMioPinsForButtons() {
	mz_gpio_init(&MIO_SWError, &Gpio_inst, SW_stop, INPUT_PIN);
	mz_gpio_init(&MIO_SWSystem, &Gpio_inst, SW_system, INPUT_PIN);
	mz_gpio_init(&MIO_SWControl, &Gpio_inst, SW_control, INPUT_PIN);
}

static void InitializeAllPushButtons() {
	mz_PushButtonFacadeCfg swcfg;
	swcfg.Stop = &MIO_SWError;
	swcfg.EnableSystem = &MIO_SWSystem;
	swcfg.EnableControl = &MIO_SWControl;
	mz_PushButton_facade_init(swcfg);
}
;

static void enableAllMioWithLEDsAttached() {
	mz_gpio_set_enable_output(&MIO_LedReady, true);
	mz_gpio_set_enable_output(&MIO_LedRunning, true);
	mz_gpio_set_enable_output(&MIO_LedError, true);
	mz_gpio_set_enable_output(&MIO_LedUser, true);
}

static void enableAllMioWithButonsAttached() {
	mz_gpio_set_enable_output(&MIO_SWError, 1);
	mz_gpio_set_enable_output(&MIO_SWSystem, 1);
	mz_gpio_set_enable_output(&MIO_SWControl, 1);
}

static void InitializeAllStatusLEDs() {
	mz_LedfacadeCfg LEDcfg;
	LEDcfg.LedUser = &MIO_LedUser;
	LEDcfg.LedRunning = &MIO_LedRunning;
	LEDcfg.LedError = &MIO_LedError;
	LEDcfg.LedReady = &MIO_LedReady;
	mz_led_facade_init(LEDcfg);
}

static void TurnAllLEDOff() {
	mz_led_set_readyLED_off();
	mz_led_set_runningLED_off();
	mz_led_set_userLED_off();
	mz_led_set_errorLED_off();
}
