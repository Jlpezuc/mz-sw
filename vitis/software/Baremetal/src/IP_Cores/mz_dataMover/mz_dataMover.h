#ifndef MZ_DATAMOVER_H
#define MZ_DATAMOVER_H
#include "../../mz/mz_array/mz_array.h"

/**
 * @brief Returns an array with a direct pointer into the BTCM. The values of the array change independend of the software.
 *
 * @return mz_array_int16_t 
 */
mz_array_int16_t mz_dataMover_get_data_by_pointer(void);

/**
 * @brief Copies all data from TCM to buffer and retruns the buffered data.
 * 
 * @return mz_array_int16_t 
 */
mz_array_int16_t mz_dataMover_update_buffer_and_get_data(void);

/**
 * @brief Copies all data from BTCM to a buffer in the PS.
 *
 * @return void
 */
void mz_dataMover_update_buffer(void);

/**
 * @brief Returns an array with a pointer to the buffered data. The buffer is only updated by explicitly calling the update_buffer function.
 *
 * @return mz_array_int16_t Buffered data
 */
mz_array_int16_t mz_dataMover_get_data_from_buffer(void);

#endif // MZ_DATAMOVER_H