#include "../mz_HAL.h"

#include "mz_platform.h"
#include "../../../shared/mz_platform_eeprom.h"
#include "../mz_IIC/mz_iic.h"
#include "mz_platform_gpiops.h"

#define MZ_PLATFORM_SCLK_RATEKHZ	(400U)

//// Bus instance ID (currently fixed to 0 and bound to PS I²C *1*) 
#define MZ_PLATFORM_I2CBUS_INSTID	(0U)
//// Slave addresses (currently fixed, but code ready for dynamic assignment)
/// NB: MZ_PLATFORM_I2CADDR_EEPROM is defined in ../../../shared/mz_platform_eeprom.h
// 16-bit I/O expander (PCA....)
#define MZ_PLATFORM_I2CADDR_GPIO	(0x20)
// EEPROMs with MAC addresses for Ethernet
#define MZ_PLATFORM_I2CADDR_MACEE0	(0x50)		// On SoM or(/and!) on the extension board for UZ Rev04
#define MZ_PLATFORM_I2CADDR_MACEE1	(0x52)		// On UZ >=Rev05 or on the extension board for UZ Rev04

typedef enum mz_platform_gpiodrv_ {
	MZP_GPIOTYPE_I2C = 0,
	MZP_GPIOTYPE_PS,
	// Add additional GPIO types/channels here (without assigning an integer value)
	// NB: Do not add anything to/below the following line
	MZP_GPIOTYPE_CNT, MZP_GPIOTYPE_NOGPIO = MZ_NOGPO
} mz_platform_gpiodrv;

#define MZ_PLATFORM_GPIO_UNAVAILABLE	{ MZP_GPIOTYPE_NOGPIO, MZP_GPIOTYPE_NOGPIO }

typedef struct mz_platform_gpX_ {
	enum mz_platform_gpiodrv_ gpX2drv : 8;
	uint8_t gpX2pin;
} mz_platform_gpo;

typedef struct mz_platform_iomap_ {
	struct mz_platform_gpX_ gpo[MZP_GPO_CNT];
	struct mz_platform_gpX_ gpi[MZP_GPI_CNT];
} mz_platform_iomap;

typedef struct mz_platform_ {
	_Bool is_ready;

	mz_platform_iomap *iomap;

	mz_iic eeprom;
	mz_platform_eeprom data;

	mz_iic maceeprom[2];
	uint8_t maceeprom_primary;

	mz_iic gpioi2c;
	uint16_t gpioi2c_outmirror;

	XGpioPs gpiops;
} mz_platform;

#if (MZ_PLATFORM_ENABLE==1)
 static mz_platform_iomap mzp_iomap_MicroZohmRev04withExtensionBoardRev02 = {
	{
		// Cf. mz_platform_gpo_id in mz_platform.h:
		{MZP_GPIOTYPE_I2C,  0},			// I2CLED_FP1RDY
		{MZP_GPIOTYPE_I2C,  1},			// I2CLED_FP2RUN
		{MZP_GPIOTYPE_I2C,  2},			// I2CLED_FP3ERR
		{MZP_GPIOTYPE_I2C,  3},			// I2CLED_FP4USR
		{MZP_GPIOTYPE_I2C,  4},			// I2CLED_FPRING
		{MZP_GPIOTYPE_PS,  26},			// RST_PHY0
		{MZP_GPIOTYPE_PS,  27},			// RST_PHY1
		{MZP_GPIOTYPE_I2C,  5},			// I2CLED_UZEXT_LED10
		{MZP_GPIOTYPE_I2C,  6},			// I2CLED_UZEXT_LED11
		{MZP_GPIOTYPE_I2C,  7},			// I2CLED_UZEXT_LED12
		{MZP_GPIOTYPE_I2C, 12},			// I2CLED_UZEXT_BEEP1
		{MZP_GPIOTYPE_I2C, 13},			// I2CLED_UZEXT_BEEP2
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_MZD10GREEN
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_MZD11RED
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_MZD12YELLOW
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_MZD13BLUE		- NB: IO7 <-> M2
	},{
		// Cf. mz_platform_gpi_id in mz_platform.h:
		{MZP_GPIOTYPE_I2C,  8},			// I2CKEY_FP5ENABLESYS
		{MZP_GPIOTYPE_I2C,  9},			// I2CKEY_FP6ENABLECTL
		{MZP_GPIOTYPE_I2C, 10},			// I2CKEY_FP7EMERGENCYSTOP
		{MZP_GPIOTYPE_I2C, 11},			// I2CKEY_FP8
		{MZP_GPIOTYPE_I2C, 14},			// I2CKEY_UZEXT_SW1
		{MZP_GPIOTYPE_I2C, 15},			// I2CKEY_UZEXT_SW2
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CKEY_MZBB_USER
	}
 };
 static mz_platform_iomap mzp_iomap_MicroZohmRev01onBreakoutBoardRev01 = {
	{
		// Cf. mz_platform_gpo_id in mz_platform.h:
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_FP1RDY
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_FP2RUN
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_FP3ERR
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_FP4USR
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_FPRING
		{MZP_GPIOTYPE_I2C, 14},			// RST_PHY0
		{MZP_GPIOTYPE_I2C, 15},			// RST_PHY1
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_UZEXT_LED10
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_UZEXT_LED11
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_UZEXT_LED12
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_UZEXT_BEEP1
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CLED_UZEXT_BEEP2
		{MZP_GPIOTYPE_I2C, 10},			// I2CLED_MZD10GREEN
		{MZP_GPIOTYPE_I2C, 11},			// I2CLED_MZD11RED
		{MZP_GPIOTYPE_I2C, 12},			// I2CLED_MZD12YELLOW
		{MZP_GPIOTYPE_I2C, 13},			// I2CLED_MZD13BLUE
	},{
		// Cf. mz_platform_gpi_id in mz_platform.h:
		{MZP_GPIOTYPE_I2C,  6},			// I2CKEY_FP5ENABLESYS
		{MZP_GPIOTYPE_I2C,  7},			// I2CKEY_FP6ENABLECTL
		{MZP_GPIOTYPE_I2C,  8},			// I2CKEY_FP7EMERGENCYSTOP
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CKEY_FP8
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CKEY_UZEXT_SW1
		MZ_PLATFORM_GPIO_UNAVAILABLE,	// I2CKEY_UZEXT_SW2
		{MZP_GPIOTYPE_I2C,  9},			// I2CKEY_MZBB_USER
	}
 };

 static mz_platform mzp;
#endif

uint32_t mz_platform_init() {
#if (MZ_PLATFORM_ENABLE==1)
	mz_assert_false(mzp.is_ready);

	//// Primary I²C bus used by MZP (we might need a secondary for mixed-old/new combinations of UZC Rev<=04 and SoM)
	mz_iic_initbus(MZ_PLATFORM_I2CBUS_INSTID, XPAR_PSU_I2C_1_BASEADDR, XPAR_PSU_I2C_1_DEVICE_ID, XPAR_PSU_I2C_1_I2C_CLK_FREQ_HZ, MZ_PLATFORM_SCLK_RATEKHZ);

	//// Create I²C devices: EEPROM
	mz_iic_initdev(&mzp.eeprom, MZ_PLATFORM_I2CBUS_INSTID, MZ_PLATFORM_I2CADDR_EEPROM);

	int status;
	// Fetch platform data
	status = mz_iic_a16read_data(&mzp.eeprom, MZ_PLATFORM_EEPROM_INFOOFFSET, (uint8_t*) &mzp.data, sizeof(mzp.data));
	if ( XST_SUCCESS != status ) {
		mz_printf("APU: Error reading platform EEPROM!\r\n");
		return(MZ_FAILURE);
	}

	if (
			( mzp.data.hw_group == MZ_PLATFORM_HWGROUP_MAX ) &&
			( mzp.data.hw_model == MZ_PLATFORM_HWMODEL_MAX ) &&
			( mzp.data.hw_revision == MZ_PLATFORM_HWREVISION_MAX ) &&
			( mzp.data.serialdata.hw_externalserial.extserial == MZ_PLATFORM_EXTSERIAL_MAX )
	   ) {
		mz_printf("APU: Platform EEPROM is unconfigured!\r\n");
		return(MZ_FAILURE);
	} else {
		mz_platform_printinfo(&mzp.data);
	}

	// Populate IO map
	switch(mzp.data.hw_group) {
		case MZP_HWGROUP_UZOHM3:
			mzp.iomap = &mzp_iomap_MicroZohmRev04withExtensionBoardRev02;
			mzp.maceeprom_primary = 1;
			break;
		case MZP_HWGROUP_UZOHM6:
			mzp.iomap = &mzp_iomap_MicroZohmRev04withExtensionBoardRev02;
			mzp.maceeprom_primary = 1;
			break;
		case MZP_HWGROUP_MZOHM:
			mzp.iomap = &mzp_iomap_MicroZohmRev01onBreakoutBoardRev01;
			mzp.maceeprom_primary = 0;
			break;
		default:
			mz_printf("APU: Platform not supported!\r\n");
			return(MZ_FAILURE);
			break;
	}

	status = 0;
	int i;

	// Enumerate, initialize and configure GPIOs
	{
		uint8_t gpiotype_usage[MZP_GPIOTYPE_CNT] = { 0 };

		// [gpiodrv] I²C-GPIO
		uint16_t gpioi2c_confreg = 0xFFFF;			// All input
		// [gpiodrv] PS-GPIO
		mz_platform_gpiops_initxlnxcfg(&mzp.gpiops, XPAR_PSU_GPIO_0_BASEADDR, XPAR_PSU_GPIO_0_DEVICE_ID);

		// Enumerate GPOs
		for (i=0; i<MZP_GPO_CNT; i++) {
			uint8_t pin = mzp.iomap->gpo[i].gpX2pin;

			if ( MZ_NOGPO == pin )
				continue;

			enum mz_platform_gpiodrv_ drv = mzp.iomap->gpo[i].gpX2drv;

			// Count
			gpiotype_usage[drv]++;

			// Configure
			switch(drv) {
				case MZP_GPIOTYPE_I2C:
					//// [gpiodrv] I²C GPIO: Determine how to configure hardware (see below for the actual register write)
					gpioi2c_confreg &= ~(1<<pin);
					break;
				case MZP_GPIOTYPE_PS:
					//// [gpiodrv] PS GPIO: Configure hardware
					XGpioPs_SetDirectionPin(&mzp.gpiops, pin, GPIOPS_DIRECTION_OUT);
					break;
				case MZP_GPIOTYPE_CNT:
					break;
				case MZP_GPIOTYPE_NOGPIO:
					break;
			}
		}
		// Enumerate GPIs
		for (i=0; i<MZP_GPI_CNT; i++) {
			uint8_t pin = mzp.iomap->gpi[i].gpX2pin;

			if ( MZ_NOGPI == pin )
				continue;

			enum mz_platform_gpiodrv_ drv = mzp.iomap->gpi[i].gpX2drv;

			// Count
			gpiotype_usage[drv]++;

			// Configure
			switch(drv) {
				case MZP_GPIOTYPE_I2C:
					// Nothing to do here, as all pins not used as outputs (cf. above) have been pre-set as inputs (cf. gpioi2c_confreg)
					break;
				case MZP_GPIOTYPE_CNT:
					break;
				case MZP_GPIOTYPE_NOGPIO:
					break;
			}
		}

		//// [gpiodrv] I²C GPIO: Configure hardware if used
		if ( gpiotype_usage[MZP_GPIOTYPE_I2C] > 0 ) {
			// Create I²C device: GPIO
			mz_iic_initdev(&mzp.gpioi2c, MZ_PLATFORM_I2CBUS_INSTID, MZ_PLATFORM_I2CADDR_GPIO);

			// Populate (APU-)local mirror of output registers
			mzp.gpioi2c_outmirror = 0x0000;

			// Configure input/output direction according to iomap
			const uint8_t pca9535a9655e_regaddr_conf0 = 6;
			status += mz_iic_write_reg16(&mzp.gpioi2c, pca9535a9655e_regaddr_conf0, gpioi2c_confreg);
		}
	}

	//// Create I²C devices: MAC-EEPROMs (could be based on iomap, if needed)
	mz_iic_initdev(&mzp.maceeprom[0], MZ_PLATFORM_I2CBUS_INSTID, MZ_PLATFORM_I2CADDR_MACEE0);
	mz_iic_initdev(&mzp.maceeprom[1], MZ_PLATFORM_I2CBUS_INSTID, MZ_PLATFORM_I2CADDR_MACEE1);

	mz_printf("Platform IIC at %d kHz and with sum-status=%i\r\n", MZ_PLATFORM_SCLK_RATEKHZ, status);

	mzp.is_ready = true;

	return(MZ_SUCCESS);
#else
	return(MZ_FAILURE);
#endif
}

/**
 * @brief Pushes not-yet-written GPO changes to I²C hardware (NB: queuing is currently not supported for PS GPIO)
 *
 * @return XST_SUCCESS if successful or failure code in case of I²C comm error or subsystem disabled
 */
uint32_t mz_platform_gpoupdate() {
#if (MZ_PLATFORM_ENABLE==1)
	const uint8_t pca9535a9655e_regaddr_out0 = 2;

	return( mz_iic_write_reg16(&mzp.gpioi2c, pca9535a9655e_regaddr_out0, mzp.gpioi2c_outmirror) );
#else
	return(MZ_FAILURE);
#endif
}

/**
 * @brief Sets an MZP GPO
 *
 * @param mzpgpo_id ID of the GPO to be used (cf. mz_platform_gpo_id in mz_platform.h for available options).
 * @param mzpgpo_op Operation to be performed on the GPO (cf. mz_platform_gpo_op in mz_platform.h for available options).
 * @return MZ_SUCCESS if successful or failure code in case of I²C comm error or subsystem disabled
 */
uint32_t mz_platform_gposet(enum mz_platform_gpo_id mzpgpo_id, enum mz_platform_gpo_op mzpgpo_op) {
#if (MZ_PLATFORM_ENABLE==1)
	mz_assert(mzp.is_ready);

	// Look up GPO and map to pin
	mz_assert( mzpgpo_id < MZP_GPO_CNT );
	uint8_t pin = mzp.iomap->gpo[mzpgpo_id].gpX2pin;

	// Check whether this GPO exists on this platform
	if ( MZ_NOGPO == pin )
		return(MZ_FAILURE);

	int immediate = 0;

	switch(mzp.iomap->gpo[mzpgpo_id].gpX2drv) {
		case MZP_GPIOTYPE_I2C:
			switch(mzpgpo_op) {
				case MZP_GPO_ASSERT:
					immediate = 1;
					mzp.gpioi2c_outmirror |= 1<<pin;
					break;
				case MZP_GPO_ASSERT_QUEUED:
					mzp.gpioi2c_outmirror |= 1<<pin;
					break;
				case MZP_GPO_DEASSERT:
					immediate = 1;
					mzp.gpioi2c_outmirror &= ~(1<<pin);
					break;
				case MZP_GPO_DEASSERT_QUEUED:
					mzp.gpioi2c_outmirror &= ~(1<<pin);
					break;
				case MZP_GPO_TOGGLE:
					immediate = 1;
					mzp.gpioi2c_outmirror ^= 1<<pin;
					break;
				case MZP_GPO_TOGGLE_QUEUED:
					mzp.gpioi2c_outmirror ^= 1<<pin;
					break;
#if MZ_PLATFORM_OPWARN
				default:
					mz_printf("MZP: Unsupported OP=%i on GPO with ID=%2i\r\n", mzpgpo_op, mzpgpo_id);
					break;
#endif
			}

			if (immediate)
				return( mz_platform_gpoupdate() );

			break;
		case MZP_GPIOTYPE_PS:
			switch(mzpgpo_op) {
				case MZP_GPO_ASSERT:
					XGpioPs_WritePin(&mzp.gpiops, pin, 1);
					break;
				case MZP_GPO_DEASSERT:
					XGpioPs_WritePin(&mzp.gpiops, pin, 0);
					break;
				case MZP_GPO_DISABLE2TRISTATED:
					XGpioPs_SetOutputEnablePin(&mzp.gpiops, pin, GPIOPS_OUTPUTENABLE_DISABLEOP);	// FIXME: Not thread-safe → Replace via mz_platform_gpiops.c?
					break;
				case MZP_GPO_ENABLE2PUSHPULLED:
					XGpioPs_SetOutputEnablePin(&mzp.gpiops, pin, GPIOPS_OUTPUTENABLE_ENABLEOP);		// FIXME: Not thread-safe → Replace via mz_platform_gpiops.c?
					break;
#if MZ_PLATFORM_OPWARN
				default:
					mz_printf("MZP: Unsupported OP=%i on GPO with ID=%2i\r\n", mzpgpo_op, mzpgpo_id);
					break;
#endif
			}
			break;
		case MZP_GPIOTYPE_CNT:
			break;
		case MZP_GPIOTYPE_NOGPIO:
			break;
	}
	return(MZ_SUCCESS);
#else
	return(MZ_FAILURE);
#endif
}

/**
 * @brief Read six-byte MAC address from EEPROM
 *
 * @param eeprom ID of the MAC EEPROM to use.
 * @param addrbuf_p Pointer to (at least six-byte) buffer to be filled.
 * @return XST_SUCCESS if successful or failure code in case of I²C comm error or subsystem disabled
 */
uint32_t mz_platform_macread(uint8_t eeprom, uint8_t *addrbuf_p) {
#if (MZ_PLATFORM_ENABLE==1)
	mz_assert(mzp.is_ready);
	mz_assert(eeprom < sizeof(mzp.maceeprom)/sizeof(mzp.maceeprom[0]));

	const uint8_t maceeprom_addroffset = 0xFA;
	const uint8_t maceeprom_addrlength = 6;

	return( mz_iic_a8read_data(&mzp.maceeprom[eeprom], maceeprom_addroffset, addrbuf_p, maceeprom_addrlength) );
#else
	return(MZ_FAILURE);
#endif
}

/**
 * @brief Read primary six-byte MAC address from associated EEPROM
 *
 * @param addrbuf_p Pointer to (at least six-byte) buffer to be filled.
 * @return XST_SUCCESS if successful or failure code in case of I²C comm error or subsystem disabled
 */
uint32_t mz_platform_macread_primary(uint8_t *addrbuf_p) {
#if (MZ_PLATFORM_ENABLE==1)
	return( mz_platform_macread(mzp.maceeprom_primary, addrbuf_p) );
#else
	return(MZ_FAILURE);
#endif
}
