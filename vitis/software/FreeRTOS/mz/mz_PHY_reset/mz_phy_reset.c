#include "../mz_PLATFORM/mz_platform.h"
#if (MZ_PLATFORM_ENABLE==0)
 #include "../mz_GPIO/mz_gpio.h"
#endif
#include "../mz_HAL.h"
#include "mz_phy_reset.h"


#if (MZ_PLATFORM_ENABLE==0)
 #define OUTPUT_PIN				1 								//This Pin is an Output
 #define INPUT_PIN				0 								//This Pin is an Input

 #define ENABLE_PIN				1 								//This Pin is enabled
 #define DISABLE_PIN				0 								//This Pin is disabled

 #define PHY0_RESET_MIO_PIN		26U
 #define PHY1_RESET_MIO_PIN		27U


 static void mz_phy_reset_init();
 static void InitializeXilinxMioGpioInstance();

 static XGpioPs Gpio_inst;
 static mz_gpio MIO_PHY0_Reset;
 static mz_gpio MIO_PHY1_Reset;
#endif


void mz_phy_reset(void)
{
#if (MZ_PLATFORM_ENABLE==0)
	mz_phy_reset_init();
#endif

	int phy_reset_high_time_us = 20e3; //20ms = 20,000 us

	// enable apply reset
#if (MZ_PLATFORM_ENABLE==1)
	mz_platform_gposet(RST_PHY0, MZP_GPO_ENABLE2PUSHPULLED);
	mz_platform_gposet(RST_PHY0, MZP_GPO_DEASSERT);				// DEASSERT -> Drive low (i.e., assert...)

	mz_platform_gposet(RST_PHY1, MZP_GPO_ENABLE2PUSHPULLED);
	mz_platform_gposet(RST_PHY1, MZP_GPO_DEASSERT);				// DEASSERT -> Drive low (i.e., assert...)
#else
	mz_gpio_set_enable_output(&MIO_PHY0_Reset, true);
	mz_gpio_write_pin(&MIO_PHY0_Reset, false);

	mz_gpio_set_enable_output(&MIO_PHY1_Reset, true);
	mz_gpio_write_pin(&MIO_PHY1_Reset, false);
#endif

	// wait for some time as defined in data sheet
	usleep(phy_reset_high_time_us);

	// release reset and disable MIO pin
#if (MZ_PLATFORM_ENABLE==1)
	mz_platform_gposet(RST_PHY0, MZP_GPO_ASSERT);				// ASSERT -> Drive high (i.e., deassert...)
	mz_platform_gposet(RST_PHY0, MZP_GPO_DISABLE2TRISTATED);

	mz_platform_gposet(RST_PHY1, MZP_GPO_ASSERT);				// ASSERT -> Drive high (i.e., deassert...)
	mz_platform_gposet(RST_PHY1, MZP_GPO_DISABLE2TRISTATED);
#else
	mz_gpio_write_pin(&MIO_PHY0_Reset, true);
	mz_gpio_set_enable_output(&MIO_PHY0_Reset, false);

	mz_gpio_write_pin(&MIO_PHY1_Reset, true);
	mz_gpio_set_enable_output(&MIO_PHY1_Reset, false);
#endif

	mz_printf("PHY reset done\r\n");
}

#if (MZ_PLATFORM_ENABLE==0)
 static void mz_phy_reset_init() {
	InitializeXilinxMioGpioInstance();
	mz_gpio_init(&MIO_PHY0_Reset, &Gpio_inst, PHY0_RESET_MIO_PIN, OUTPUT_PIN);
	mz_gpio_init(&MIO_PHY1_Reset, &Gpio_inst, PHY1_RESET_MIO_PIN, OUTPUT_PIN);
 }

 static void InitializeXilinxMioGpioInstance() {
	XGpioPs_Config gpio_config;
	gpio_config.BaseAddr = XPAR_PSU_GPIO_0_BASEADDR; // e.g.: XPAR_PSU_GPIO_0_BASEADDR;
	gpio_config.DeviceId = XPAR_PSU_GPIO_0_DEVICE_ID; // e.g.: XPAR_PSU_GPIO_0_DEVICE_ID;
	int status = XGpioPs_CfgInitialize(&Gpio_inst, &gpio_config, gpio_config.BaseAddr);
	mz_assert_false(status); // 0 -> no error
 }
#endif

