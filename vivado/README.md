# vivado – proyecto Vivado `microzohm`

Proyecto de PL del MicroZohm. Es la versión reducida y ordenada del proyecto original
(`mz-sw (old)/vivado`), sin los bloques heredados de proyectos anteriores. Toda la nomenclatura derivada del UltraZohm (`ultrazohm`, `zusys`, `uz_*`)
pasa a ser MicroZohm (`microzohm`, `mzsys`, `mz_*`); todos los IPs se publican como
`microzohm:user:MZ_<NOMBRE>:<versión>` (ver `ip_cores/README.md`). Solo se conservan `uz_` en
los nombres de módulos de software que se citan en comentarios.

## Estructura

```
vivado/
├── build.tcl                 # crea project/microzohm.xpr desde cero
├── bd/mzsys.tcl              # block design "mzsys" (única fuente de verdad del diseño)
├── board_files/              # Trenz TE0808_9EG (board part por defecto)
├── constraints/te0808_mz/    # XDC recortados: solo los puertos que existen
└── project/                  # proyecto generado por build.tcl; se versionan microzohm.xpr, mzsys/mzsys.bd y el wrapper (ver project/.gitignore)
```

Todos los IP cores (`microzohm:user:*`) se toman de `mz-sw/ip_cores` (ver su README).
Los scripts auxiliares (`vivado_export_xsa.tcl`, `vivado_clean_workspace.tcl`, `ci_vivado_*`)
están en `mz-sw/tcl_scripts`.

## Construir

```tcl
# Consola Tcl de Vivado 2022.2
cd <mz-sw>/vivado
source build.tcl
# después: Generate Bitstream y  source ../tcl_scripts/vivado_export_xsa.tcl
```

En batch: `vivado -mode batch -source build.tcl`.

Si se modifica el VHDL de algún IP propio de `ip_cores/<ip>/hdl/`, re-ejecutar
`ip_cores/package_all_ips.tcl` y volver a lanzar `build.tcl`.

## Qué contiene el block design `mzsys`

| Bloque | Función |
|---|---|
| `zynq_ultra_ps_e_0` | PS con la misma configuración que el original (`PSU__USE__IRQ1` desactivada) |
| `mz_system/` | `smartconnect_0` (1 reloj, 11 maestros), `proc_sys_reset_100MHz`, `timer_uptime_64bit`, `mz_enable/` (AXI GPIO de habilitación), `interrupt_clock/` (Clocking Wizard + `MZ_CLOCK_DIV`, reloj de la interrupción) |
| `mz_analog_adapter/` | `A1_adapter` (`MZ_ADC_LTC2311` + IOBUFDS + `MZ_AVERAGER_8CH` + GPIO de config), `A2_adapter` (`MZ_ADC_LTC2311` + IOBUFDS), `A3_adapter` (`MZ_ADC_MAX11331`), `clock_flag_div_axi_mz_0` (trigger de conversión de A1/A2, `MZ_CLOCK_FLAG_DIV`), `DataMover/` (`MZ_AXI2TCM` → TCM del R5) |
| `mz_digital_adapter/` | Mapeo de `AXI_PWM_0` (G1..G4, square, enable) a `D1_OUT[23:0]` invertido, mismos bits que el original |
| `AXI_PWM_0`, `AXI_PHASE_DETECTOR_v_0` | Nivel superior (`MZ_AXI_PWM`, `MZ_AXI_PHASE_DETECTOR`), mismos nombres de instancia que el original (sus `XPAR_*` no cambian) |

* **Un solo reloj**: `pl_clk0` a 100 MHz para todo (el `clk_wiz` del original generaba
  también 100 MHz, así que `FCLK`/`PWM_CLK_FREQ` del software siguen siendo válidos).
* **Reloj de la interrupción**: `mz_system/interrupt_clock` = Clocking Wizard (frecuencia base por AXI) + `MZ_CLOCK_DIV` (divisor por AXI, ≥ 1); lo programa `main.c` con `mz_interruptClock` (`MZ_INTERRUPT_CLOCK_BASE_HZ` / N = `MZ_ISR_FREQUENCY_HZ`).
* **Una sola interrupción PL→PS**: `mz_system/irq` → `pl_ps_irq0[0]` (`XPS_FPGA0_INT_ID`,
  que es lo que usa `isr.h` con `INTERRUPT_ISR_SOURCE_USER_CHOICE 0`). La misma señal es la
  base de tiempo de `MZ_CLOCK_FLAG_DIV` (trigger de los LTC2311) y del `MZ_AVERAGER_8CH`.
* Direcciones AXI idénticas a las del proyecto original para todos los periféricos conservados
  (los nombres de las jerarquías `mz_*` sí cambian los `XPAR_*`, ver más abajo).
* Patrón de habilitación del Safety CPLD conservado: `D*_OUT_26/27 = 0`, `D*_OUT_28/29 = Enable_Gate`.

## Eliminado respecto al proyecto original

* `clk_wiz` (×2) y los resets de 50/25/10 MHz.
* `axi_timebase_wdt` (no lo usa el software).
* Bloque `Interrupt` completo: `mux_axi_ip`, `delay_trigger`, VIO `adc_delay`, VIO `vio_interrupt`, `Concat_interrupts`.
* Toda la modulación excepto `AXI_PWM`: `PWM_and_SS_control_V4` (×4), `uz_interlockDeadtime2L` (×3), `PWM_SS_3L` + `top_npc_state_machine` (3L), `angle2SS_IPAXI` (SHE), `state_machine_2L_CCB`.
* Encoder incremental D5 (`Dig_12/13_Ch5`), puertos `D2_IN_18/19`, `D2_OUT2_0`, `D3_OUT`, `D4_OUT`.
* Todas las ILA / system_ila / VIO de depuración y el `adc_ltc2311_debug.xdc`.

## Estado de verificación

* `build.tcl` genera el proyecto y `validate_bd_design` pasa sin errores (Vivado 2022.2).
* `generate_target` + `write_hw_platform` (sin bitstream) funcionan; el `.hwh` resultante
  conserva las mismas direcciones que el original para todos los periféricos y exporta el
  driver de `MZ_CLOCK_FLAG_DIV` (necesario para que `xparameters.h` siga definiendo
  `XPAR_MZ_ANALOG_ADAPTER_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR`).
* **Síntesis / implementación no ejecutadas**: este PC no tiene licencia de Vivado para el
  `xczu9eg`. Hay que generar el bitstream en la máquina con licencia (la del laboratorio).

## Cambios necesarios en el software de Vitis

### 1. Nombres nuevos (`uz_` → `mz_`)

Las jerarquías renombradas cambian el prefijo de sus `XPAR_*` en `xparameters.h`:

| Antes (`mz-sw (old)/vivado`) | Ahora |
|---|---|
| `XPAR_UZ_SYSTEM_UZ_ENABLE_AXI_GPIO_2_BASEADDR` | `XPAR_MZ_SYSTEM_MZ_ENABLE_AXI_GPIO_2_BASEADDR` |
| `XPAR_UZ_SYSTEM_TIMER_UPTIME_64BIT_DEVICE_ID` / `_CLOCK_FREQ_HZ` | `XPAR_MZ_SYSTEM_TIMER_UPTIME_64BIT_DEVICE_ID` / `_CLOCK_FREQ_HZ` |
| `XPAR_UZ_ANALOG_ADAPTER_A1_ADAPTER_A1_ADC_LTC2311_S00_AXI_BASEADDR` | `XPAR_MZ_ANALOG_ADAPTER_A1_ADAPTER_A1_ADC_LTC2311_S00_AXI_BASEADDR` |
| `XPAR_UZ_ANALOG_ADAPTER_A2_ADAPTER_A2_ADC_LTC2311_S00_AXI_BASEADDR` | `XPAR_MZ_ANALOG_ADAPTER_A2_ADAPTER_A2_ADC_LTC2311_S00_AXI_BASEADDR` |
| `XPAR_UZ_ANALOG_ADAPTER_A3_ADAPTER_ADC_MAX11331_TOP_0_BASEADDR` | `XPAR_MZ_ANALOG_ADAPTER_A3_ADAPTER_ADC_MAX11331_TOP_0_BASEADDR` |
| `XPAR_UZ_ANALOG_ADAPTER_A1_ADAPTER_AXI_GPIO_0_BASEADDR` | `XPAR_MZ_ANALOG_ADAPTER_A1_ADAPTER_AXI_GPIO_0_BASEADDR` |

Ficheros afectados: `hw_init/gpio_axi.c`, `uz/uz_SystemTime/uz_SystemTime.c`,
`hw_init/uz_adcLtc2311_ip_core_init.c`, `hw_init/uz_adcMax11331_ip_core_init.c`, `sw/isr.c`
(`AXI_GPIO`). Sin cambio: `XPAR_AXI_PWM_0_BASEADDR`, `XPAR_AXI_PHASE_DETECTOR_V_0_BASEADDR`,
`XPAR_MZ_ANALOG_ADAPTER_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR`.

El bitstream/XSA pasan a llamarse `mzsys_wrapper.bit` / `mzsys_wrapper.xsa`:
`vitis_generate_UltraZohm_workspace.tcl` coge el primer `*.xsa` de `vivado_exported_xsa/`
(dejar solo uno), pero las configuraciones `*.launch` y
`tcl_scripts/vitis_debug_freertos_baremetal_fpga.tcl` tienen `zusys_wrapper` escrito a mano.

### 2. IPs que ya no existen

Al desaparecer IPs de la PL, dejan de existir sus `XPAR_*` en `xparameters.h`.
Con el `main.c` actual hay que quitar (o condicionar) en `init_ip_cores`:

* `uz_interlockDeadtime2L_staticAllocator_slotD1_pin_*` (×4) y `initialize_pwm_2l_on_D1_pin_*` (×4)
  → `XPAR_UZ_DIGITAL_ADAPTER_D1_ADAPTER_GATES_*`, `XPAR_UZ_DIGITAL_ADAPTER_D4_ADAPTER_PWM_AND_SS_CONTROL_V_0_BASEADDR`
* `PWM_3L_Initialize()` → `XPAR_UZ_DIGITAL_ADAPTER_D2_ADAPTER_GATES_3L_PWM_SS_3L_IP_0_BASEADDR`
* `initialize_uz_mux_axi()` → `XPAR_UZ_SYSTEM_INTERRUPT_MUX_AXI_IP_1_BASEADDR`
* En `isr.c`, las llamadas a `uz_PWM_SS_2L_set_duty_cycle` / `PWM_3L_SetDutyCycle` si las hubiera
  (en la versión actual ya no se usan).

Todo lo demás que usa `isr.c`/`main.c` conserva el mismo nombre y dirección:
`XPAR_AXI_PWM_0_BASEADDR`, `XPAR_AXI_PHASE_DETECTOR_V_0_BASEADDR`,
`XPAR_MZ_ANALOG_ADAPTER_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR`, `XPAR_UZ_ANALOG_ADAPTER_A1_ADAPTER_AXI_GPIO_0_BASEADDR`,
`XPAR_UZ_ANALOG_ADAPTER_A1/A2_ADAPTER_A*_ADC_LTC2311_S00_AXI_BASEADDR`,
`XPAR_UZ_ANALOG_ADAPTER_A3_ADAPTER_ADC_MAX11331_TOP_0_BASEADDR`,
`XPAR_UZ_SYSTEM_UZ_ENABLE_AXI_GPIO_2_BASEADDR`, `XPAR_UZ_SYSTEM_TIMER_UPTIME_64BIT_*`.
