# vitis – software `microzohm`

Software del MicroZohm, pareja del proyecto de PL `mz-sw/vivado`. Es la versión reducida y
ordenada del original (`mz-sw (old)/vitis`).
Solo contiene el software que la aplicación actual usa realmente, y toda la nomenclatura
derivada del UltraZohm pasa a MicroZohm:

| Antes (`mz-sw (old)/vitis`) | Ahora |
|---|---|
| carpeta `src/uz/`, ficheros `uz_*.c/.h`, funciones `uz_*()`, tipos `uz_*_t`, macros `UZ_*` | `src/mz/`, `mz_*`, `mz_*()`, `mz_*_t`, `MZ_*` |
| `ultrazohm_state_machine_*()` | `microzohm_state_machine_*()` |
| plataforma Vitis `UltraZohm`, `zusys_wrapper.xsa/.bit` | `MicroZohm`, `mzsys_wrapper.xsa/.bit` |
| `uzp*` / `UZP_*` (plataforma FreeRTOS) | `mzp*` / `MZP_*` |
| `XPAR_UZ_SYSTEM_*`, `XPAR_UZ_ANALOG_ADAPTER_*` | `XPAR_MZ_SYSTEM_*`, `XPAR_MZ_ANALOG_ADAPTER_*` (coinciden con el `mzsys` de `vivado`) |

## Estructura

```
vitis/
├── software/
│   ├── Baremetal/          # R5_0: aplicación de control (Ceedling: project.yml + test/)
│   │   └── src/
│   │       ├── main.c, main.h, defines.h, globalData.h, lscript.ld
│   │       ├── user/       lo que cambia con cada experimento: isr.c/.h (ISR_Control) + parametros, tablas, algoritmos
│   │       ├── app/        plataforma (cada modulo con su .c y su .h): ipc_ARM, javascope, adc, gpio_axi,
│   │       │               mz_platform_state_machine, mz_assertion_configuration, mz_adc*_ip_core_init
│   │       ├── IP_Cores/   mz_adcLtc2311, mz_adcMax11331, mz_dataMover, mz_interruptClock, mz_adcSampleClock, mz_averager
│   │       └── mz/         mz_HAL.h, mz_AXI.h, mz_global_configuration.h + módulos del framework
│   ├── FreeRTOS/           # A53_0: lwIP/TCP hacia el JavaScope, IPI con el R5 (mz/ renombrado)
│   ├── shared/             # APU_RPU_shared.h, mz_platform_eeprom.h
│   ├── FSBL/, BootImage/   # sin cambios (FSBL.elf sirve: la configuración del PS es la misma)
│   └── *.launch            # configuraciones de debug (bitstream mzsys_wrapper.bit)
├── vivado_exported_xsa/    # aquí va mzsys_wrapper.xsa (tcl_scripts/vivado_export_xsa.tcl); solo un .xsa
│                           # scripts XSCT (vitis_*) y de CI (ci_vitis_*): mz-sw/tcl_scripts
├── workspace/              # generado (no versionar)
└── Packages/, mz_vitis_key_bindings.epf
```

## Generar el workspace

1. Generar el bitstream en `vivado` y exportar con `source ../../tcl_scripts/vivado_export_xsa.tcl` (desde `vivado/project`)
   (deja `vitis/vivado_exported_xsa/mzsys_wrapper.xsa`).
2. Abrir Vitis 2022.2 con el workspace `vitis/workspace`.
3. En la consola XSCT:

```tcl
cd [getws]
source {../../tcl_scripts/vitis_generate_MicroZohm_workspace.tcl}
```

Para actualizar la plataforma tras un nuevo XSA: `source {../../tcl_scripts/vitis_update_platform.tcl}`.
Debug: configuración `Debug_FreeRTOS_Baremetal_FPGA` (se copia al workspace al generarlo).

`mz_global_configuration.h` se incluye ya creado (el original lo trataba como fichero local no
versionado); solo contiene `HARDWARE_VERSION` y los `*_MAX_INSTANCES`. Las frecuencias de la
interrupcion y del muestreo de los ADC, los factores de conversion y las direcciones base estan en
el bloque `PARAMETROS DE ARRANQUE` al principio de `Baremetal/src/main.c` (ver la pagina *Start-up*
de la documentacion).

## Arranque (`main.c`)

Cinco estados: `init_platform` (aserciones, GPIO `mz_enable` con CPLD y DataMover a 0, LEDs/botones),
`init_software` (tiempo de sistema, scope), `init_ip_cores` (ADC: `app/mz_adc*_ip_core_init.c`,
`mz_interruptClock`,
`mz_adcSampleClock`, arranque del DataMover), `init_interrupts` (resumen por UART, `Initialize_ISR`)
e `infinite_loop` (maquina de estados). Cada estado llama a una funcion `mz_init_*` de `main.c`.
El CPLD lo habilita la maquina de estados al entrar en *running* (`mz_axigpio_enable_cpld`).

## Qué se conserva del framework (cierre de dependencias desde `main.c`/`isr.c`)

`IP_Cores/`: `mz_adcLtc2311`, `mz_adcMax11331`, `mz_dataMover`, `mz_interruptClock` (nuevo),
`mz_adcSampleClock` (nuevo, driver de `MZ_CLOCK_FLAG_DIV`).
`mz/`: `mz_HAL`, `mz_AXI`, `mz_SystemTime`, `mz_LED`, `mz_PushButton`, `mz_GPIO`,
`mz_MioGpio_mediator`, `mz_array`, `mz_fixedpoint`, `mz_Transformation` (tipos `mz_3ph_*` que usa
`isr.c`). Libreria de control documentada pero sin usar en la aplicacion actual: `mz_signals`,
`mz_piController`, `mz_PMSM_config`, `mz_CurrentControl` (`main.c` ya no instancia el control de
corriente).
Tests de Ceedling de esos módulos (17 ficheros frente a 94).

## Eliminado respecto al original

* Drivers de IPs que ya no están en la PL: `PWM_SS_2L`, `interlockDeadtime2L`, `PWM_SS_3L`,
  `mux_axi`, `incrementalEncoder`, `resolverIP`, `dq_transformation`, `pmsmModel*`,
  `mlp_three_layer`, `dac_interface`, `inverter_3ph`, `inverter_adapter`, `myIP2`/`axiTestIP`,
  `simscapeExample`, y sus `hw_init` (`pwm_init.c`, `pwm_3L_driver.c`, `mux_axi.c`, `encoder.c`).
* Módulos del framework no usados: `wavegen`, `nn`, `matrix`, `movingAverageFilter`,
  `newton_raphson`, `ResonantController`, `Space_Vector_Modulation`, `SpeedControl`,
  `setpoint`, `sum`, `complex`, `exponential_smoothing`, `integrator`, `controlToolbox`.
* `Codegen/` (Embedded Coder) y `SimulinkCodegen/`.
* En el código de aplicación: inicialización de PWM 2L/3L, interlocks y `mux_axi` en `main.c`;
  `object_pointers_t` de `globalData.h`; el enable/disable de interlocks en la máquina de
  estados; includes muertos en `isr.c`.
* Configuración: `isr.h` queda con una sola fuente de interrupción (`XPS_FPGA0_INT_ID` =
  `AXI_PWM_1/square`); `mz_global_configuration.h` pierde `INTERRUPT_*_USER_CHOICE`, los
  defines del encoder D5 y los `*_MAX_INSTANCES` de módulos eliminados, y gana
  `MZ_ISR_FREQUENCY_HZ` (10 kHz), que es lo que `main.c` programa en `AXI_PWM_1`.
* `vitis.zip` (backup) y los proyectos sueltos del workspace (`proce_prueba`, `cortexr5_1`).

Sin cambios funcionales: `isr.c` (experimento PWM/detector de fase), `ipc_ARM.c`,
`javascope.c/.h` y todo el lado FreeRTOS. Los ficheros de investigación del experimento
ASHE-ANN (`funciones_sogi.h`, `nn_*CCB*`, `pesos_sesgos_*.h`, `CCB_params.h`) se borraron el
2026-09-15 porque ya no se usaban (el bucle de entrenamiento no está en `isr.c`); siguen en
`mz-sw (old)/vitis/software/Baremetal/src`.

## Estado de verificación

Workspace generado con `xsct` (Vitis 2022.2) usando un XSA de `vivado` sin bitstream:
plataforma `MicroZohm` + BSPs creados, `Baremetal.elf` (R5) y `FreeRTOS.elf` (A53)
compilan y enlazan sin errores contra el `xparameters.h` nuevo (`XPAR_MZ_SYSTEM_*`,
`XPAR_MZ_ANALOG_ADAPTER_*`, `XPAR_AXI_PWM_*`, `XPAR_CLOCK_FLAG_DIV_AXI_MZ_0_S00_AXI_BASEADDR`).
Los únicos warnings son de lwIP/BSP de Xilinx. Pendiente probar en hardware con el
bitstream generado en la máquina con licencia. Los tests de Ceedling no se han ejecutado
(no hay Ruby/Ceedling en este PC).
