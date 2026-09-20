//APU_RPU_shared.h

#pragma once

// OCM Bank 3 starts at         0xFFFF0000
// See UG1085 page 533 (https://www.xilinx.com/support/documentation/user_guides/ug1085-zynq-ultrascale-trm.pdf#G20.375357)

#define MEM_SHARED_START 	0xFFFF0000
#define MEM_SHARED_MID1 	0xFFFF8000
#define MEM_SHARED_MID2 	0xFFFF8800
#define MEM_SHARED_MID3 	0xFFFF9000
#define MEM_SHARED_MID4 	0xFFFF9800
#define MEM_SHARED_MID5 	0xFFFFA000
#define MEM_SHARED_MID6 	0xFFFFA800
#define MEM_SHARED_MID7 	0xFFFFB000

#define JS_CHANNELS 		20

#define Data_CH				8

// update by hand when changing JS_CHANNELS
// Bank 3 of OCM has 64 KB, thus a maximum of 16K float values can be stored
#define JAVASCOPE_DATA_SIZE_2POW  	128


struct javascope_data_t
{
	uint32_t    status;
	float	    slowDataContent;
	uint32_t    slowDataID;
	float       scope_ch[JS_CHANNELS];
};

struct APU_to_RPU_t
{
	uint32_t id;
	float value;
};

struct Shared_Data
{
	float value[Data_CH];
};
