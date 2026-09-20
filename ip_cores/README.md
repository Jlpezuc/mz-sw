# ip_cores – repositorio de IP cores del MicroZohm

Único repositorio de IPs que usa `vivado/build.tcl` (`ip_repo_paths = ../ip_cores`).

## Convenio de nombres

| Elemento | Convenio | Ejemplo |
|---|---|---|
| Carpeta | `MZ_<NOMBRE>_<versión>` | `MZ_AXI_PWM_1.0` |
| VLNV (catálogo de Vivado) | `microzohm:user:MZ_<NOMBRE>:<versión>` | `microzohm:user:MZ_AXI_PWM:1.0` |
| Entidad top | `MZ_<NOMBRE>` | `MZ_AXI_PWM` |
| Fuentes | `hdl/MZ_<NOMBRE>*.vhd`; esclavo AXI4-Lite `*_S00_AXI.vhd`; paquete `*_PKG.vhd`; sub-bloques `*_<BLOQUE>.vhd` | `MZ_CLOCK_FLAG_DIV_CORE.vhd` |
| GUI de Vivado | `xgui/MZ_<NOMBRE>_v<mayor>_<menor>.tcl` (lo genera Vivado) | `xgui/MZ_AXI_PWM_v1_0.tcl` |
| Driver de Vitis (opcional) | `drivers/MZ_<NOMBRE>_v<mayor>_<menor>/{data,src}` | `drivers/MZ_CLOCK_FLAG_DIV_v1_0/` |
| Testbenches (opcional) | `sim/TB_MZ_<NOMBRE>*.vhd` | `sim/TB_MZ_ADC_LTC2311.vhd` |
| Automatización de BD (opcional) | `bd/bd.tcl` | |

Nombres en MAYÚSCULAS con prefijo `MZ_` (VHDL no distingue mayúsculas; así el nombre del
fichero, de la entidad y del IP coinciden). Los nombres de **instancia** en `mzsys`
(`AXI_PWM_0`, `A1_ADC_LTC2311`, `clock_flag_div_axi_mz_0`, …) no dependen del nombre del IP y
se mantienen para que los `XPAR_*` del software no cambien.

```
ip_cores/
├── MZ_<NOMBRE>_<versión>/
│   ├── component.xml      # descripción IP-XACT (interfaces, parámetros, ficheros)
│   ├── hdl/               # fuentes VHDL
│   ├── xgui/              # GUI de parámetros en Vivado
│   ├── drivers/           # (opcional) driver de Vitis
│   ├── bd/                # (opcional) bd.tcl con reglas de conexión automática
│   └── sim/               # (opcional) testbenches
├── package_all_ips.tcl    # re-empaqueta los IPs escritos a mano a partir de hdl/
└── README.md
```

## IPs

### Instanciados en `mzsys`

| IP | VLNV | Origen | Uso en `mzsys` |
|---|---|---|---|
| `MZ_AXI_PWM_1.0` | `microzohm:user:MZ_AXI_PWM:1.0` | propio | `AXI_PWM_0` compuertas D1 (0/90/180/270°) |
| `MZ_AXI_PHASE_DETECTOR_1.0` | `microzohm:user:MZ_AXI_PHASE_DETECTOR:1.0` | propio | cuenta ciclos entre `D2_IN_PHASE` y `AXI_PWM_0/square` |
| `MZ_CLOCK_FLAG_DIV_1.0` | `microzohm:user:MZ_CLOCK_FLAG_DIV:1.0` | propio; incluye driver de Vitis | divisor del trigger de conversión de los LTC2311 (`MZ_ADC_SAMPLE_FREQUENCY_HZ`), en `mz_analog_adapter` |
| `MZ_CLOCK_DIV_1.0` | `microzohm:user:MZ_CLOCK_DIV:1.0` | propio | divisor de reloj programable por AXI (`clk / N`, cualquier entero ≥ 1); `mz_system/interrupt_clock/clock_div_0` genera la interrupción del ISR a partir del Clocking Wizard |
| `MZ_AVERAGER_8CH_1.0` | `microzohm:user:MZ_AVERAGER_8CH:1.0` | propio | promedio de N muestras de los 8 canales de A1 (`MAX_AVG_LOG2`) |
| `MZ_IOBUFDS_1.0` | `microzohm:user:MZ_IOBUFDS:1.0` | propio (antes `vivado/src/hdl/iobufds_inst.vhd` como *module reference*) | buffers LVDS (`OBUFDS`/`IBUFDS`) del SPI de A1/A2 |
| `MZ_ADC_MAX11331_1.0` | `microzohm:user:MZ_ADC_MAX11331:1.0` | propio (VHDL del framework) | ADC lento A3 (16 canales, 12 bit) |
| `MZ_ADC_LTC2311_3.0` | `microzohm:user:MZ_ADC_LTC2311:3.0` | framework UltraZohm (antes `UltraZohm:user:ADC_LTC2311`) | ADC rápidos A1/A2 (16 bit, LVDS) |
| `MZ_AXI2TCM_1.1` | `microzohm:user:MZ_AXI2TCM:1.1` | framework UltraZohm (antes `TUM:user:AXI2TCM`) | DataMover: copia los 32 valores de ADC a la TCM del R5, en `mz_analog_adapter` |

### Disponibles en el catálogo (no instanciados)

Están en el repositorio para poder añadirlos al diseño desde el catálogo de IPs de Vivado; `mzsys`
no los usa y el software actual no tiene driver para ellos (los drivers `uz_*` están en `mz-sw (old)`).

| IP | VLNV | Origen | Función |
|---|---|---|---|
| `MZ_DELAY_TRIGGER_1.0` | `microzohm:user:MZ_DELAY_TRIGGER:1.0` | propio (VHDL suelto `Delay_signal`) | retardo programable de una señal (0..2047 ciclos) |
| `MZ_EXTEND_INTERRUPT_1.0` | `microzohm:user:MZ_EXTEND_INTERRUPT:1.0` | propio (VHDL suelto `Extend_Interrupt`) | alarga un pulso de interrupción a ≥ 60 ciclos |
| `MZ_INTERLOCK_3L_1.0` | `microzohm:user:MZ_INTERLOCK_3L:1.0` | propio (VHDL suelto `Interlock_Module_3L`) | interlock y tiempo muerto de inversor NPC 3 niveles (3 fases) |
| `MZ_PWM_SS_2L_4.1` | `microzohm:user:MZ_PWM_SS_2L:4.1` | HDL Coder (`PWM_and_SS_control_V4_ip`) | PWM / estados de conmutación, inversor 2 niveles |
| `MZ_PWM_SS_3L_1.4` | `microzohm:user:MZ_PWM_SS_3L:1.4` | HDL Coder (`PWM_SS_3L`) | PWM / estados de conmutación, inversor NPC 3 niveles |
| `MZ_INTERLOCK_DEADTIME_2L_1.0` | `microzohm:user:MZ_INTERLOCK_DEADTIME_2L:1.0` | HDL Coder (`uz_interlockDeadtime2L`) | interlock y tiempo muerto, inversor 2 niveles |
| `MZ_ANGLE2SS_1.0` | `microzohm:user:MZ_ANGLE2SS:1.0` | Vivado (`angle2SS_IPAXI`) | modulación SHE: ángulos por AXI → estados de conmutación |
| `MZ_COUNTER_F_SW_1.0` | `microzohm:user:MZ_COUNTER_F_SW:1.0` | HDL Coder (`Counter_f_sw_V2_ip`) | contador de conmutaciones (frecuencia de conmutación real) |
| `MZ_MSOGI_1.0` | `microzohm:user:MZ_MSOGI:1.0` | Vivado (`mSOGI_AXI`) | **experimental**: banco de 5 SOGI; no elabora tal cual (wrapper y `sogi_1` incompletos) |
| `MZ_MUX_AXI_1.2` | `microzohm:user:MZ_MUX_AXI:1.2` | HDL Coder (`mux_axi_ip`) | multiplexor de interrupción/trigger seleccionable por AXI |
| `MZ_TRANS_123_DQ_1.0` | `microzohm:user:MZ_TRANS_123_DQ:1.0` | HDL Coder (`Trans_123_dq_V12_ip`) | transformación abc ↔ dq |
| `MZ_SIXPHASE_VSD_TRANSFORMATION_1.0` | `microzohm:user:MZ_SIXPHASE_VSD_TRANSFORMATION:1.0` | HDL Coder | transformación VSD de 6 fases |
| `MZ_NINEPHASE_VSD_TRANSFORMATION_1.0` | `microzohm:user:MZ_NINEPHASE_VSD_TRANSFORMATION:1.0` | HDL Coder | transformación VSD de 9 fases |
| `MZ_INCREMENTAL_ENCODER_24.0` | `microzohm:user:MZ_INCREMENTAL_ENCODER:24.0` | HDL Coder (`IncreEncoder_V24_ip`) | encoder incremental (posición, velocidad) |
| `MZ_RESOLVER_INTERFACE_1.0` | `microzohm:user:MZ_RESOLVER_INTERFACE:1.0` | Vivado (`uz_resolverIP`) | interfaz con el resolver AD2S1210 |
| `MZ_DAC_SPI_INTERFACE_1.0` | `microzohm:user:MZ_DAC_SPI_INTERFACE:1.0` | HDL Coder (`uz_dac_spi_interface`) | interfaz SPI del DAC (adaptador DAC) |
| `MZ_INVERTER_ADAPTER_1.0` | `microzohm:user:MZ_INVERTER_ADAPTER:1.0` | HDL Coder (`uz_d_inverter_adapter`) | driver del adaptador de inversor (estados, temperaturas) |
| `MZ_INVERTER_ADAPTER_MAPPING_1.0` | `microzohm:user:MZ_INVERTER_ADAPTER_MAPPING:1.0` | Vivado (`mapping_ip_core`) | mapeo de pines del adaptador de inversor |
| `MZ_INVERTER_3PH_1.0` | `microzohm:user:MZ_INVERTER_3PH:1.0` | HDL Coder (`uz_inverter_3ph`) | modelo de inversor trifásico (HIL) |
| `MZ_PMSM_MODEL_1.0` | `microzohm:user:MZ_PMSM_MODEL:1.0` | HDL Coder (`uz_pmsm_model`) | modelo de PMSM (HIL) |
| `MZ_PMSM_MODEL_6PH_DQ_1.0` | `microzohm:user:MZ_PMSM_MODEL_6PH_DQ:1.0` | HDL Coder | modelo de PMSM de 6 fases en dq (HIL) |
| `MZ_PMSM_MODEL_9PH_DQ_1.0` | `microzohm:user:MZ_PMSM_MODEL_9PH_DQ:1.0` | HDL Coder | modelo de PMSM de 9 fases en dq (HIL) |
| `MZ_PLANT_MODEL_PT1_1.0` | `microzohm:user:MZ_PLANT_MODEL_PT1:1.0` | HDL Coder (`uz_plantModel_pt1`) | modelo de planta PT1 (HIL) |
| `MZ_MLP_THREE_LAYER_3.0` | `microzohm:user:MZ_MLP_THREE_LAYER:3.0` | HDL Coder (`uz_mlp_three_layer`) | red neuronal MLP de 3 capas |
| `MZ_RS_FLIP_FLOP_1.0` | `microzohm:user:MZ_RS_FLIP_FLOP:1.0` | HDL Coder (`uz_rs_flip_flop`) | biestable RS con AXI |
| `MZ_AXI_TEST_IP_1.0` | `microzohm:user:MZ_AXI_TEST_IP:1.0` | Vivado (`uz_axi_testIP`) | IP de ejemplo AXI4-Lite (plantilla) |
| `MZ_SIMSCAPE_EXAMPLE_1.0` | `microzohm:user:MZ_SIMSCAPE_EXAMPLE:1.0` | HDL Coder (`uz_simscapeExample`) | ejemplo de modelo Simscape convertido a IP |

La documentación de cada IP (qué hace y qué necesita: relojes, resets, AXI, puertos, parámetros,
registros) está en `docs/source/mpsoc/ip_cores/`; la sección *Interface* de cada página la genera
`docs/make_ip_docs.py` a partir de `component.xml`.

## Modificar un IP

* **IPs propios** (los de `ip_list` en `package_all_ips.tcl`): editar `hdl/*.vhd` y ejecutar en la consola Tcl de
  Vivado `cd <mz-sw>/ip_cores; source package_all_ips.tcl`, que regenera `component.xml` y
  `xgui/` de todos ellos a partir de la lista `ip_list` del script (carpeta, entidad top,
  nombre visible, asociaciones reloj/bus/reset, driver). Después `source build.tcl` en `vivado/`.
* **IPs importados del framework** (`MZ_ADC_LTC2311_3.0`, `MZ_AXI2TCM_1.1` y los generados con
  HDL Coder / Vivado de la segunda tabla): se conservan tal y como los empaquetó el framework
  (parámetros con dependencias, `bd/bd.tcl`, `include/*_addr.h`). Solo se cambiaron la carpeta,
  el VLNV (`component.xml`) y el periférico soportado del driver (`*.mdd`); las entidades y
  ficheros VHDL mantienen su nombre original (`ADC_LTC2311_v3_0`, `AXI2TCM_v1_0`,
  `uz_pmsm_model_v1_0`, …): renombrarlos a ciegas rompería el IP. Para cambiarlos, abrir
  `component.xml` con *Tools → Edit Packaged IP* en Vivado. Los modelos de Simulink y los
  proyectos de HDL Coder con los que se generaron siguen en `mz-sw (old)/ip_cores`.

## Añadir un IP nuevo

1. Crear `MZ_<NOMBRE>_1.0/hdl/` con la entidad top `MZ_<NOMBRE>` y sus fuentes.
2. Añadir una línea a `ip_list` en `package_all_ips.tcl` y ejecutarlo.
3. Añadir la ruta de su `component.xml` a la comprobación de `vivado/build.tcl` y usarlo en
   `vivado/bd/mzsys.tcl` como `microzohm:user:MZ_<NOMBRE>:1.0`.
4. Si el software necesita `XPAR_<instancia>_S00_AXI_BASEADDR`, incluir un driver mínimo
   como el de `MZ_CLOCK_FLAG_DIV_1.0/drivers` (ver `how_to_create_ip_core_driver` en la docs).

## Lo que no está aquí

Los modelos de Simulink, proyectos de HDL Coder (`hdl_prj`) y proyectos de edición de Vivado con los
que se generaron los IPs importados siguen en `mz-sw (old)/ip_cores`; aquí solo está la carpeta
empaquetada (`component.xml`, fuentes, `xgui`, drivers).
