#ifndef MZ_PLATFORM_EEPROM_H
#define MZ_PLATFORM_EEPROM_H

#include <stdint.h>

#define MZ_PLATFORM_I2CADDR_EEPROM		(0x5B)
#define MZ_PLATFORM_EEPROM_INFOOFFSET	(0x78)

enum mz_platform_eeprom_group {
	MZP_HWGROUP_ADCARD =	000,
	MZP_HWGROUP_UZOHM3 =	001,
	MZP_HWGROUP_UZOHM6 =	002,
	MZP_HWGROUP_MZOHM =		003,
	MZP_HWGROUP_EXTERNAL =	998,
	MZP_HWGROUP_DUMMY	 =	999,
};

#define MZ_PLATFORM_HWMODEL_EXTOFFSET	(500U)

#pragma pack(push,1)
	typedef struct mz_platform_batchandserial_ {
		uint8_t  batch;
		uint16_t serial;
	} mz_platform_batchandserial;
	typedef struct mz_platform_externalserial_ {
		uint32_t extserial : 24;
	} mz_platform_externalserial;
#pragma pack(pop)

typedef struct mz_platform_eeprom_ {
	enum mz_platform_eeprom_group hw_group : 10;
	uint8_t fflags_model : 6;
	uint16_t hw_model : 10;
	uint8_t fflags_revision : 6;
	uint8_t hw_revision;
	union {
		struct mz_platform_batchandserial_ hw_batchandserial;
		struct mz_platform_externalserial_ hw_externalserial;
	} serialdata;
} mz_platform_eeprom;

#define MZ_PLATFORM_HWGROUP_MAX		(1023U)		// 10 bit
#define MZ_PLATFORM_HWMODEL_MAX		(1023U)		// 10 bit
#define MZ_PLATFORM_HWREVISION_MAX	(255U)		//  8 bit
#define MZ_PLATFORM_EXTSERIAL_MAX	(0xFFFFFF)	// 24 bit

#define MZ_PLATFORM_FFLAGS2STR(STR, FFLAGS)		\
	char STR[7];								\
	mz_platform_fflags2str_helper(STR, FFLAGS, sizeof(STR)/sizeof(STR[0]));
void mz_platform_fflags2str_helper(char *str, uint8_t fflags, size_t size) {
	size--;

	str += size;
	*str = '\0';

	int i;
	for(i=0; i<size; i++)
		*(--str) = (fflags & (1<<i)) ? '1' : '0';
}

void mz_platform_printinfo(mz_platform_eeprom *eeprom) {
	mz_printf("/=================\\\r\n");
	if (MZP_HWGROUP_EXTERNAL == eeprom->hw_group) {
		mz_printf("Hw group:       Ext\r\n");
	} else {
		mz_printf("Hw group:       %03i\r\n", eeprom->hw_group);
	}

	MZ_PLATFORM_FFLAGS2STR(fflags_model, eeprom->fflags_model)
	mz_printf("Hw model:       %03i (flags %s=0x%02X)\r\n", eeprom->hw_model, fflags_model, eeprom->fflags_model);

	MZ_PLATFORM_FFLAGS2STR(fflags_revision, eeprom->fflags_revision)
	mz_printf("Hw revision:     %02i (flags %s=0x%02X)\r\n", eeprom->hw_revision, fflags_revision, eeprom->fflags_revision);

	if (MZP_HWGROUP_EXTERNAL == eeprom->hw_group) {
		mz_printf("Ext. serial: %06i\r\n", eeprom->serialdata.hw_externalserial.extserial);
	} else {
		mz_printf("Hw batch:        %02i\r\n", eeprom->serialdata.hw_batchandserial.batch);
		mz_printf("Hw serial:     %04i\r\n", eeprom->serialdata.hw_batchandserial.serial);
	}
	mz_printf("\\=================/\r\n");
}

#endif
