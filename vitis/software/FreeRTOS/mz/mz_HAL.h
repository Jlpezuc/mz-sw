#ifndef MZ_HAL_H
#define MZ_HAL_H

#include <stdint.h>
#include <stdbool.h>
#include <math.h>

#ifndef TEST
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_printf.h"
#include "sleep.h"

/**
 * @brief Asserts that the condition is true. If false, the assertion callback executes (program is stopped).
 * 
 */
#define mz_assert(Expression)                 \
  do {                                        \
      if(!(Expression)){                      \
      Xil_Assert(__FILE__, __LINE__);         \
    }                                         \
  } while (0)


/**
 * @brief Prints to stdout, i.e., Vitis terminal
 * 
 */
#define mz_printf xil_printf

/**
 * @brief Processor does nothing for defined seconds
 * 
 */
#define mz_sleep_seconds sleep

/**
 * @brief Processor does nothing for defined microseconds
 * 
 */
#define mz_sleep_useconds usleep

/**
 * @brief Return this define to indicate success in a function and check return value.
 * 
 */
#define MZ_SUCCESS XST_SUCCESS

/**
 * @brief Return this define to indicate failure in a function and check return value.
 * 
 */
#define MZ_FAILURE XST_FAILURE

#endif
#ifdef TEST
// cppcheck-suppress misra-c2012-21.6 //. stdio.h is not allowed by MISRA, we use it only with ceedling unit testing and never on the MicroZohm
#include <stdio.h>
#include <unistd.h>
#include "CException.h"
#define mz_assert(condition) if (!(condition)) Throw(0)
#define mz_printf printf
#define mz_sleep_seconds sleep
#define mz_sleep_useconds usleep
#define MZ_SUCCESS 0U
#define MZ_FAILURE 1U
#endif

/**
 * @brief Asserts that the argument is not a NULL pointer.
 * 
 */
#define mz_assert_not_NULL(Expression) \
{                              \
    mz_assert((Expression)!=NULL);        \
}

// No doxygen documentation since this should not be used in new code
// Will be deleted in the future
#define mz_assert_not_zero(Expression) \
{                              \
    mz_assert((Expression)!=0);        \
}

/**
 * @brief Asserts that the argument of type uint32_t is not zero (!=0).
 * 
 */
#define mz_assert_not_zero_uint32(Expression) \
{                              \
    mz_assert((Expression)!=(uint32_t)0);        \
}

/**
 * @brief Asserts that the argument of type int32_t is not zero (!=0).
 * 
 */
#define mz_assert_not_zero_int32(Expression) \
{                              \
    mz_assert((Expression)!=(int32_t)0);        \
}

/**
 * @brief Asserts that the argument of type int is not zero (!=0).
 * 
 */
#define mz_assert_not_zero_int(Expression) \
{                              \
    mz_assert((Expression)!=(int)0);        \
}

/**
 * @brief Asserts that the argument of type unsigned int is not zero (!=0).
 * 
 */
#define mz_assert_not_zero_unsigned_int(Expression) \
{                              \
    mz_assert((Expression)!=0U);        \
}

/**
 * @brief Asserts that the argument is false.
 * 
 */
#define mz_assert_false(Expression) \
{                              \
    mz_assert ((Expression)==false);        \
}

// No doxygen documentation since this should not be used in new code
// Will be deleted in the future
#define mz_assert_true(Expression) \
{                              \
    mz_assert( (Expression) ==true);        \
}
#endif // Endif of guard

