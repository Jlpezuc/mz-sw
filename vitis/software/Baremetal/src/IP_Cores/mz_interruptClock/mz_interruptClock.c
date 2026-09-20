/******************************************************************************
 * mz_interruptClock.c - ver mz_interruptClock.h
 *
 * Registros del Clocking Wizard v6 (PG065, reconfiguracion dinamica, MMCM):
 *   0x000  reset software (escribir 0x0A)
 *   0x004  estado: bit 0 = locked
 *   0x200  [7:0] DIVCLK_DIVIDE  [15:8] CLKFBOUT_MULT  [25:16] CLKFBOUT_FRAC (milesimas)  [26] FRAC_EN
 *   0x204  CLKFBOUT_PHASE
 *   0x208  [7:0] CLKOUT0_DIVIDE [17:8] CLKOUT0_FRAC (milesimas)  [18] FRAC_EN
 *   0x20C  CLKOUT0_PHASE
 *   0x25C  bit 0 LOAD, bit 1 SEN (secuencia del ejemplo de Xilinx: 0x07 y despues 0x02)
 * Registros de MZ_CLOCK_DIV: 0x00 DIVIDER, 0x04 CONTROL (bit 0 enable), 0x08 STATUS (bit 0 running).
 ******************************************************************************/
#include "mz_interruptClock.h"
#include "../../mz/mz_HAL.h"
#include "xil_io.h"
#include <math.h>

// Limites del MMCME4 (Zynq UltraScale+, XCZU9EG-1)
#define MMCM_VCO_MIN_HZ      800.0e6f
#define MMCM_VCO_MAX_HZ     1600.0e6f
#define MMCM_PFD_MIN_HZ       10.0e6f
#define MMCM_PFD_MAX_HZ      500.0e6f
#define MMCM_OUT_MAX_HZ      775.0e6f
#define MMCM_D_MAX           106U
#define MMCM_M8_MIN          16U      // 2.000
#define MMCM_M8_MAX          1024U    // 128.000
#define MMCM_O8_MIN          8U       // 1.000
#define MMCM_O8_MAX          1024U    // 128.000

#define CLK_WIZ_REG_RESET        0x000U
#define CLK_WIZ_REG_STATUS       0x004U
#define CLK_WIZ_REG_CLKFB        0x200U
#define CLK_WIZ_REG_CLKFB_PHASE  0x204U
#define CLK_WIZ_REG_CLKOUT0      0x208U
#define CLK_WIZ_REG_CLKOUT0_PH   0x20CU
#define CLK_WIZ_REG_LOAD         0x25CU
#define CLK_WIZ_STATUS_LOCKED    0x1U

#define CLOCK_DIV_REG_DIVIDER    0x00U
#define CLOCK_DIV_REG_CONTROL    0x04U
#define CLOCK_DIV_REG_STATUS     0x08U

static struct mz_interruptClock_config_t cfg;
static bool is_ready = false;
static float current_isr_frequency_Hz = 0.0f;

void mz_interruptClock_init(struct mz_interruptClock_config_t config)
{
    mz_assert_not_zero(config.base_address_clk_wiz);
    mz_assert_not_zero(config.base_address_clock_div);
    mz_assert(config.input_frequency_Hz > 0.0f);
    cfg = config;
    is_ready = true;
}

struct mz_interruptClock_setting_t mz_interruptClock_calculate(float f_in, float f_base, float f_isr)
{
    struct mz_interruptClock_setting_t best = {0};
    mz_assert(f_in > 0.0f && f_base > 0.0f && f_isr > 0.0f);
    mz_assert(f_base <= MMCM_OUT_MAX_HZ);

    float best_err = INFINITY;
    bool best_integer = false;
    // Busqueda: D y M (en octavos) -> VCO valido; O ideal = VCO / f_base, redondeado a octavos
    for (uint32_t d = 1U; d <= MMCM_D_MAX; d++) {
        float f_pfd = f_in / (float)d;
        if (f_pfd < MMCM_PFD_MIN_HZ) break;
        if (f_pfd > MMCM_PFD_MAX_HZ) continue;
        for (uint32_t m8 = MMCM_M8_MIN; m8 <= MMCM_M8_MAX; m8++) {
            float f_vco = f_pfd * (float)m8 / 8.0f;
            if (f_vco < MMCM_VCO_MIN_HZ) continue;
            if (f_vco > MMCM_VCO_MAX_HZ) break;
            float o8_ideal = f_vco * 8.0f / f_base;
            uint32_t cand[2] = {(uint32_t)floorf(o8_ideal), (uint32_t)ceilf(o8_ideal)};
            for (int k = 0; k < 2; k++) {
                uint32_t o8 = cand[k];
                if (o8 < MMCM_O8_MIN || o8 > MMCM_O8_MAX) continue;
                float f = f_vco * 8.0f / (float)o8;
                float err = fabsf(f - f_base);
                bool integer = ((m8 % 8U) == 0U) && ((o8 % 8U) == 0U);
                // mejor error; a igualdad, preferir M y O enteros (menos jitter) y D pequeno
                if (err < best_err - 1e-3f || (fabsf(err - best_err) <= 1e-3f && integer && !best_integer)) {
                    best_err = err;
                    best_integer = integer;
                    best.divclk_divide = d;
                    best.clkfbout_mult8 = m8;
                    best.clkout_divide8 = o8;
                    best.base_frequency_Hz = f;
                }
            }
        }
    }
    mz_assert(best.clkout_divide8 != 0U); // no hay configuracion valida para f_base
    // Divisor entero que mejor aproxima f_isr a partir de la base real
    float n = best.base_frequency_Hz / f_isr;
    best.divider = (n < 1.0f) ? 1U : (uint32_t)(n + 0.5f);
    best.isr_frequency_Hz = best.base_frequency_Hz / (float)best.divider;
    return best;
}

float mz_interruptClock_choose_base_frequency(float isr_frequency_Hz, uint32_t samples_per_isr, float preferred_base_Hz)
{
    mz_assert(is_ready);
    mz_assert(isr_frequency_Hz > 0.0f && samples_per_isr >= 1U && preferred_base_Hz > 0.0f);
    // paso entre bases validas: f_isr * 2 * muestras (asi N / muestras es par)
    float step = isr_frequency_Hz * 2.0f * (float)samples_per_isr;
    mz_assert(step <= MMCM_OUT_MAX_HZ); // ni la base minima cabe en el MMCM: bajar f_isr o las muestras
    float f_min = MMCM_VCO_MIN_HZ / (MMCM_O8_MAX / 8.0f);   // salida minima del MMCM (6.25 MHz)
    uint32_t k_lo = (uint32_t)ceilf(f_min / step);
    uint32_t k_hi = (uint32_t)floorf(MMCM_OUT_MAX_HZ / step);
    if (k_lo < 1U) k_lo = 1U;
    // candidatos alrededor de la base preferida (+-8 pasos), acotados al rango del MMCM
    uint32_t k_center = (uint32_t)(preferred_base_Hz / step + 0.5f);
    uint32_t k_a = (k_center > k_lo + 8U) ? k_center - 8U : k_lo;
    uint32_t k_b = (k_center + 8U < k_hi) ? k_center + 8U : k_hi;
    if (k_a > k_b) { k_a = k_lo; k_b = k_lo; }
    float best_base = 0.0f, best_err = INFINITY, best_dist = INFINITY;
    for (uint32_t k = k_a; k <= k_b; k++) {
        float base = step * (float)k;
        struct mz_interruptClock_setting_t s = mz_interruptClock_calculate(cfg.input_frequency_Hz, base, isr_frequency_Hz);
        float err = fabsf(s.base_frequency_Hz - base);        // error del MMCM
        float dist = fabsf(base - preferred_base_Hz);
        if (err < best_err - 1.0f || (fabsf(err - best_err) <= 1.0f && dist < best_dist)) {
            best_err = err; best_dist = dist; best_base = base;
        }
    }
    mz_assert(best_base > 0.0f);
    return best_base;
}

static void clk_wiz_program(const struct mz_interruptClock_setting_t *s)
{
    uint32_t m_int = s->clkfbout_mult8 / 8U;
    uint32_t m_frac = (s->clkfbout_mult8 % 8U) * 125U;   // milesimas
    uint32_t o_int = s->clkout_divide8 / 8U;
    uint32_t o_frac = (s->clkout_divide8 % 8U) * 125U;
    uint32_t reg_fb = (m_frac ? (1U << 26) : 0U) | (m_frac << 16) | (m_int << 8) | (s->divclk_divide & 0xFFU);
    uint32_t reg_o0 = (o_frac ? (1U << 18) : 0U) | (o_frac << 8) | (o_int & 0xFFU);
    uint32_t base = cfg.base_address_clk_wiz;
    Xil_Out32(base + CLK_WIZ_REG_CLKFB, reg_fb);
    Xil_Out32(base + CLK_WIZ_REG_CLKFB_PHASE, 0U);
    Xil_Out32(base + CLK_WIZ_REG_CLKOUT0, reg_o0);
    Xil_Out32(base + CLK_WIZ_REG_CLKOUT0_PH, 0U);
    Xil_Out32(base + CLK_WIZ_REG_LOAD, 0x7U);
    Xil_Out32(base + CLK_WIZ_REG_LOAD, 0x2U);
    // esperar el enganche del MMCM
    uint32_t locked = 0U;
    for (uint32_t i = 0U; i < 2000000U; i++) {
        locked = Xil_In32(base + CLK_WIZ_REG_STATUS) & CLK_WIZ_STATUS_LOCKED;
        if (locked) break;
    }
    mz_assert(locked); // el Clocking Wizard no engancha con estos parametros
}

struct mz_interruptClock_setting_t mz_interruptClock_set_frequency(float base_frequency_Hz, float isr_frequency_Hz)
{
    mz_assert(is_ready);
    struct mz_interruptClock_setting_t s = mz_interruptClock_calculate(cfg.input_frequency_Hz, base_frequency_Hz, isr_frequency_Hz);
    uint32_t div = cfg.base_address_clock_div;
    Xil_Out32(div + CLOCK_DIV_REG_CONTROL, 0U);          // parar el divisor mientras cambia el reloj
    clk_wiz_program(&s);
    Xil_Out32(div + CLOCK_DIV_REG_DIVIDER, s.divider);   // el divisor se carga al habilitar
    Xil_Out32(div + CLOCK_DIV_REG_CONTROL, 1U);
    current_isr_frequency_Hz = s.isr_frequency_Hz;
    return s;
}

float mz_interruptClock_get_isr_frequency_Hz(void)
{
    return current_isr_frequency_Hz;
}

bool mz_interruptClock_is_running(void)
{
    mz_assert(is_ready);
    bool locked = (Xil_In32(cfg.base_address_clk_wiz + CLK_WIZ_REG_STATUS) & CLK_WIZ_STATUS_LOCKED) != 0U;
    bool running = (Xil_In32(cfg.base_address_clock_div + CLOCK_DIV_REG_STATUS) & 0x1U) != 0U;
    return locked && running;
}

void mz_interruptClock_stop(void)
{
    mz_assert(is_ready);
    Xil_Out32(cfg.base_address_clock_div + CLOCK_DIV_REG_CONTROL, 0U);
    current_isr_frequency_Hz = 0.0f;
}
