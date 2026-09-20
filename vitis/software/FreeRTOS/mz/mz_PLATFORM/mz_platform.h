#ifndef MZ_PLATFORM_H
#define MZ_PLATFORM_H

#include <stdint.h>

// (De)Activate UZ auto-platform detection and platform-specific I/O-HAL framework (NB: disabling it turns most of its hooks into failing NOPs...)
#define MZ_PLATFORM_ENABLE	(1U)

// (De)Activate run-time warnings for (currently) unsupported GPIO operations
#define MZ_PLATFORM_OPWARN	(0U)

uint32_t mz_platform_init();
void mz_platform_printinfo();

// GPOs supported by this framework
enum mz_platform_gpo_id {
	I2CLED_FP1RDY = 0, I2CLED_FP2RUN, I2CLED_FP3ERR, I2CLED_FP4USR,
	I2CLED_FPRING,
	RST_PHY0, RST_PHY1,
	I2CLED_UZEXT_LED10, I2CLED_UZEXT_LED11, I2CLED_UZEXT_LED12,
	I2CLED_UZEXT_BEEP1, I2CLED_UZEXT_BEEP2,
	I2CLED_MZD10GREEN, I2CLED_MZD11RED, I2CLED_MZD12YELLOW, I2CLED_MZD13BLUE,
	//// NB: Do not add anything to/below the following line
	MZP_GPO_CNT, MZ_NOGPO = 255 };
// GPO operations (currently not all ops supported on all output drivers, cf. mz_platform.c)
enum mz_platform_gpo_op {
	MZP_GPO_DISABLE2TRISTATED = 0,		// Disable and tri-state the output
	MZP_GPO_ENABLE2PUSHPULLED,			// Enable and actively drive the output
	MZP_GPO_ASSERT,						// Assert output (i.e., high for non-inverted ones)	\ NB: Inversion is not yet
	MZP_GPO_DEASSERT,					// De-assert output (i.e., high for inverted ones)	/     implemented -> TODO!
	MZP_GPO_TOGGLE,						// Toggle output between asserted and de-asserted
	MZP_GPO_ASSERT_QUEUED,
	MZP_GPO_DEASSERT_QUEUED,
	MZP_GPO_TOGGLE_QUEUED,
};

// GPIs supported by this framework
enum mz_platform_gpi_id {
	I2CKEY_FP5ENABLESYS = 0, I2CKEY_FP6ENABLECTL, I2CKEY_FP7EMERGENCYSTOP, I2CKEY_FP8,
	I2CKEY_UZEXT_SW1, I2CKEY_UZEXT_SW2,
	I2CKEY_MZBB_USER,
	//// NB: Do not add anything to/below the following line
	MZP_GPI_CNT, MZ_NOGPI = MZ_NOGPO };

uint32_t mz_platform_gpoupdate();
uint32_t mz_platform_gposet(enum mz_platform_gpo_id mzpgpo_id, enum mz_platform_gpo_op mzpgpo_op);

uint32_t mz_platform_macread(uint8_t eeprom, uint8_t *addr);
uint32_t mz_platform_macread_primary(uint8_t *addrbuf_p);

#endif
