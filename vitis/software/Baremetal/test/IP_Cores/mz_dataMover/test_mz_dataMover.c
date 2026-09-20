#ifdef TEST

#include "unity.h"

#include "mz_dataMover.h"
#include "mz_array.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_mz_DataMover_pointer_address_to_BTCM(void)
{
    mz_array_int16_t test=mz_dataMover_get_data_by_pointer();
    TEST_ASSERT_EQUAL_PTR (0x00020000U, test.data); // just tests that the hard-coded pointer to the BTCM start address is returned
}



#endif // TEST
