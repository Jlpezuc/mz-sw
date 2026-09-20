#ifndef MZ_IIC_H
#define MZ_IIC_H

#include <stdint.h>

typedef struct mz_iic_ {
	uint8_t businst;
	_Bool is_ready;
	uint8_t devaddr;
} mz_iic;

void mz_iic_initbus(uint8_t businst, uintptr_t xlnx_baseaddress, uint16_t xlnx_deviceid, uint32_t xlnx_inputclock_hz, int busfreq_khz);
void mz_iic_initdev(mz_iic *self, uint8_t businst, uint8_t devaddr);
uint32_t mz_iic_write_reg16(struct mz_iic_ *self, uint8_t regaddr, uint16_t data);
uint32_t mz_iic_write_raw(struct mz_iic_ *self, uint8_t* data, int32_t cnt);
uint32_t mz_iic_a8read_data(struct mz_iic_ *self, uint8_t regaddr, uint8_t*, int32_t cnt);
uint32_t mz_iic_a16read_data(struct mz_iic_ *self, uint16_t regaddr, uint8_t*, int32_t cnt);

#endif
