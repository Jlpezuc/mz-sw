################################################################
# Block design "mzsys" - MicroZohm
#
# Version reducida del block design original de mz-sw/vivado.
# Se conserva unicamente lo que el software de Vitis (R5 baremetal +
# A53 FreeRTOS) necesita para funcionar igual que con el proyecto
# original:
#
#   - PS (Zynq UltraScale+), misma configuracion que el original
#   - mz_system      : smartconnect, reset, timer 64 bit (uz_SystemTime),
#                      mz_enable (AXI GPIO de habilitacion),
#                      interrupt_clock (Clocking Wizard + MZ_CLOCK_DIV, ambos por
#                      AXI: reloj de la interrupcion del ISR)
#   - mz_analog_adapter : A1/A2 (LTC2311 + IOBUFDS + averager en A1), A3 (MAX11331),
#                      el trigger de conversion (clock_flag_div) y el DataMover (AXI2TCM
#                      -> TCM del R5)
#   - mz_digital_adapter: mapeo de las compuertas de AXI_PWM_0 a D1_OUT
#   - AXI_PWM_0, AXI_PHASE_DETECTOR, clock_flag_div_axi_mz,
#     -> a nivel superior, con
#     los mismos nombres de instancia para que los XPAR_* del software no
#     cambien.
#
# Reloj de la logica: pl_clk0 (100 MHz). El reloj de la interrupcion se genera
# en mz_system/interrupt_clock: Clocking Wizard (frecuencia base programable por
# AXI, p. ej. 100 MHz) -> MZ_CLOCK_DIV (divisor programable por AXI, >= 1).
# Una unica interrupcion PL->PS: mz_system/irq -> pl_ps_irq0 bit 0
# (XPS_FPGA0_INT_ID). La misma senal es la base de tiempo del trigger de
# los ADC (clock_flag_div_axi_mz) y del averager.
#
# Eliminado respecto al original: AXI_PWM_1, resets de 50/25/10 MHz, watchdog,
# mux_axi/delay_trigger/VIO de interrupciones, todas las ILA/VIO, PWM_SS_2L,
# interlocks, PWM 3L, angle2SS (SHE), state_machine_2L_CCB, encoder D5.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}
   return 1
}

################################################################
# START
################################################################

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu9eg-ffvc900-1-e
   set_property BOARD_PART trenz.biz:te0808_9eg_1e:part0:3.0 [current_project]
}

# CHANGE DESIGN NAME HERE
variable design_name
set design_name mzsys

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.
set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default
  # the value is script directory path)
  set origin_dir ./project

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."
     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}
     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."
     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}
     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."
     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -dir $str_bd_folder $design_name
} else {
  # Create regular design
  if { [catch {create_bd_design $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."
     return 1
  }
}

current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\
xilinx.com:ip:zynq_ultra_ps_e:3.4\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_timer:2.0\
xilinx.com:ip:clk_wiz:6.0\
microzohm:user:MZ_CLOCK_DIV:1.0\
microzohm:user:MZ_IOBUFDS:1.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:util_vector_logic:2.0\
microzohm:user:MZ_ADC_LTC2311:3.0\
microzohm:user:MZ_AXI2TCM:1.1\
microzohm:user:MZ_AXI_PWM:1.0\
microzohm:user:MZ_AXI_PHASE_DETECTOR:1.0\
microzohm:user:MZ_CLOCK_FLAG_DIV:1.0\
microzohm:user:MZ_AVERAGER_8CH:1.0\
microzohm:user:MZ_ADC_MAX11331:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################

# Cabecera comun de todas las celdas jerarquicas
proc _hier_begin { parentCell nameHier procName } {
  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "${procName}() - Empty argument(s)!"}
     return ""
  }
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return ""
  }
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return ""
  }
  current_bd_instance $parentObj
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj
  return $hier_obj
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_system/mz_enable
#   AXI GPIO de 8 bits escrito por el R5 (uz_axigpio_*):
#     bit1 -> ENABLE_CPLD_HIGH   (patron de habilitacion del Safety CPLD: D*_OUT_28/29)
#     bit4 -> ENABLE_AXI2TCM (arranque del DataMover y enable_measure del MAX11331)
#   Enable_Gates_CPLD_Low: constante 0 para D*_OUT_26/27
# ---------------------------------------------------------------
proc create_hier_cell_mz_enable { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_mz_enable]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_pin -dir O -from 0 -to 0 ENABLE_CPLD_LOW
  create_bd_pin -dir O -from 0 -to 0 ENABLE_CPLD_HIGH
  create_bd_pin -dir O -from 0 -to 0 ENABLE_AXI2TCM
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn

  set Enable_Gates_CPLD_Low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 Enable_Gates_CPLD_Low ]
  set_property CONFIG.CONST_VAL {0} $Enable_Gates_CPLD_Low

  set axi_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_2 ]
  set_property CONFIG.C_GPIO_WIDTH {8} $axi_gpio_2

  set xlslice_Enable_Gate_Bit1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_Enable_Gate_Bit1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {1} \
    CONFIG.DIN_TO {1} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_Enable_Gate_Bit1

  set xlslice_Enable_AXI2TCM_Bit4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_Enable_AXI2TCM_Bit4 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {4} \
    CONFIG.DIN_TO {4} \
    CONFIG.DIN_WIDTH {8} \
    CONFIG.DOUT_WIDTH {1} \
  ] $xlslice_Enable_AXI2TCM_Bit4

  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_2/S_AXI]

  connect_bd_net -net Enable_Gates_CPLD_Low_dout [get_bd_pins ENABLE_CPLD_LOW] [get_bd_pins Enable_Gates_CPLD_Low/dout]
  connect_bd_net -net axi_gpio_2_gpio_io_o [get_bd_pins axi_gpio_2/gpio_io_o] [get_bd_pins xlslice_Enable_Gate_Bit1/Din] [get_bd_pins xlslice_Enable_AXI2TCM_Bit4/Din]
  connect_bd_net -net xlslice_Enable_Gate_Dout [get_bd_pins ENABLE_CPLD_HIGH] [get_bd_pins xlslice_Enable_Gate_Bit1/Dout]
  connect_bd_net -net xlslice_Enable_AXI2TCM_Dout [get_bd_pins ENABLE_AXI2TCM] [get_bd_pins xlslice_Enable_AXI2TCM_Bit4/Dout]
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins s_axi_aclk] [get_bd_pins axi_gpio_2/s_axi_aclk]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_gpio_2/s_axi_aresetn]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_analog_adapter/DataMover
#   AXI2TCM copia los 32 valores de ADC (A1: 8, A2: 8, A3: 16) a la TCM
#   del R5 cada vez que A1 entrega datos validos y el bit ENABLE_AXI2TCM
#   esta activo.
# ---------------------------------------------------------------
proc create_hier_cell_DataMover { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_DataMover]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI

  create_bd_pin -dir I -from 127 -to 0 ADC_A1
  create_bd_pin -dir I -from 127 -to 0 ADC_A2
  create_bd_pin -dir I -from 255 -to 0 ADC_A3
  create_bd_pin -dir I -from 0 -to 0 ENABLE_AXI2TCM
  create_bd_pin -dir I -from 0 -to 0 Trigger_AXI2TCM
  create_bd_pin -dir I -type clk m00_axi_aclk
  create_bd_pin -dir I -type rst m00_axi_aresetn

  set AXI2TCM_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_AXI2TCM:1.1 AXI2TCM_0 ]
  set_property CONFIG.C_M00_NUMBER_of_ADCs {32} $AXI2TCM_0

  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property CONFIG.C_SIZE {1} $util_vector_logic_0

  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {3} $xlconcat_0

  connect_bd_intf_net -intf_net AXI2TCM_0_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins AXI2TCM_0/M00_AXI]

  connect_bd_net -net ADC_A1_1 [get_bd_pins ADC_A1] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net ADC_A2_1 [get_bd_pins ADC_A2] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net ADC_A3_1 [get_bd_pins ADC_A3] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net ADCs_ADC_values_raw [get_bd_pins AXI2TCM_0/DATA_IN] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net Trigger_AXI2TCM_1 [get_bd_pins Trigger_AXI2TCM] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net ENABLE_AXI2TCM_1 [get_bd_pins ENABLE_AXI2TCM] [get_bd_pins util_vector_logic_0/Op2]
  connect_bd_net -net init_axi2tcm [get_bd_pins AXI2TCM_0/init_axi_txn] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net m00_axi_aresetn_1 [get_bd_pins m00_axi_aresetn] [get_bd_pins AXI2TCM_0/m00_axi_aresetn]
  connect_bd_net -net m00_axi_aclk_1 [get_bd_pins m00_axi_aclk] [get_bd_pins AXI2TCM_0/m00_axi_aclk]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_system/interrupt_clock
#   Reloj de la interrupcion del ISR:
#     clk_wiz_0 (Clocking Wizard, reconfigurable por AXI): pl_clk0 -> f_base
#     clock_div_0 (MZ_CLOCK_DIV, divisor por AXI, >= 1): f_base / N -> irq
#   'locked' del clk_wiz es el reset del divisor (no cuenta sin reloj estable).
# ---------------------------------------------------------------
proc create_hier_cell_interrupt_clock { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_interrupt_clock]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CLK_WIZ
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_DIV
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir O irq
  create_bd_pin -dir O -type clk clk_base
  create_bd_pin -dir O locked

  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.USE_DYN_RECONFIG {true} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0

  set clock_div_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_CLOCK_DIV:1.0 clock_div_0 ]

  connect_bd_intf_net -intf_net S_AXI_CLK_WIZ_1 [get_bd_intf_pins S_AXI_CLK_WIZ] [get_bd_intf_pins clk_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net S_AXI_DIV_1     [get_bd_intf_pins S_AXI_DIV]     [get_bd_intf_pins clock_div_0/s00_axi]
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins s_axi_aclk] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins clk_wiz_0/s_axi_aclk] [get_bd_pins clock_div_0/s00_axi_aclk]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins clk_wiz_0/s_axi_aresetn] [get_bd_pins clock_div_0/s00_axi_aresetn]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins clock_div_0/clk] [get_bd_pins clk_base]
  connect_bd_net -net clk_wiz_0_locked   [get_bd_pins clk_wiz_0/locked] [get_bd_pins clock_div_0/resetn] [get_bd_pins locked]
  connect_bd_net -net clock_div_0_clk_out [get_bd_pins clock_div_0/clk_out] [get_bd_pins irq]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_system
#   Infraestructura: reset, smartconnect (1 reloj, 11 maestros),
#   timer 64 bit de uz_SystemTime, mz_enable e interrupt_clock.
# ---------------------------------------------------------------
proc create_hier_cell_mz_system { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_mz_system]
  if { $hier_obj eq "" } { return }

  # Desde el PS
  create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  # Maestros AXI-Lite hacia los perifericos
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_A1_ADC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_A2_ADC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_A3_ADC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_A1_GPIO
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_PWM_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_PHASE_DETECTOR
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CLOCK_FLAG_DIV

  create_bd_pin -dir O -from 0 -to 0 ENABLE_CPLD_LOW
  create_bd_pin -dir O -from 0 -to 0 ENABLE_CPLD_HIGH
  create_bd_pin -dir O -from 0 -to 0 ENABLE_AXI2TCM
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O irq
  create_bd_pin -dir O -type clk clk_base

  create_hier_cell_mz_enable $hier_obj mz_enable
  create_hier_cell_interrupt_clock $hier_obj interrupt_clock

  set proc_sys_reset_100MHz [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_100MHz ]

  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MI {11} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0

  set timer_uptime_64bit [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 timer_uptime_64bit ]
  set_property CONFIG.mode_64bit {1} $timer_uptime_64bit

  # Interfaces
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins M_AXI_A1_ADC]         [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins M_AXI_A2_ADC]         [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins M_AXI_A3_ADC]         [get_bd_intf_pins smartconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins M_AXI_A1_GPIO]        [get_bd_intf_pins smartconnect_0/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins smartconnect_0/M04_AXI] [get_bd_intf_pins timer_uptime_64bit/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins smartconnect_0/M05_AXI] [get_bd_intf_pins mz_enable/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M06_AXI [get_bd_intf_pins M_AXI_PWM_0]          [get_bd_intf_pins smartconnect_0/M06_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M07_AXI [get_bd_intf_pins smartconnect_0/M07_AXI] [get_bd_intf_pins interrupt_clock/S_AXI_CLK_WIZ]
  connect_bd_intf_net -intf_net smartconnect_0_M08_AXI [get_bd_intf_pins M_AXI_PHASE_DETECTOR] [get_bd_intf_pins smartconnect_0/M08_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M09_AXI [get_bd_intf_pins M_AXI_CLOCK_FLAG_DIV] [get_bd_intf_pins smartconnect_0/M09_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M10_AXI [get_bd_intf_pins smartconnect_0/M10_AXI] [get_bd_intf_pins interrupt_clock/S_AXI_DIV]

  # Senales
  connect_bd_net -net mz_enable_ENABLE_AXI2TCM [get_bd_pins ENABLE_AXI2TCM] [get_bd_pins mz_enable/ENABLE_AXI2TCM]
  connect_bd_net -net mz_enable_ENABLE_CPLD_HIGH [get_bd_pins ENABLE_CPLD_HIGH] [get_bd_pins mz_enable/ENABLE_CPLD_HIGH]
  connect_bd_net -net mz_enable_ENABLE_CPLD_LOW [get_bd_pins ENABLE_CPLD_LOW] [get_bd_pins mz_enable/ENABLE_CPLD_LOW]
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins proc_sys_reset_100MHz/ext_reset_in]
  connect_bd_net -net proc_sys_reset_100MHz_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins proc_sys_reset_100MHz/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins timer_uptime_64bit/s_axi_aresetn] [get_bd_pins mz_enable/s_axi_aresetn] [get_bd_pins interrupt_clock/s_axi_aresetn]
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins proc_sys_reset_100MHz/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins timer_uptime_64bit/s_axi_aclk] [get_bd_pins mz_enable/s_axi_aclk] [get_bd_pins interrupt_clock/s_axi_aclk]
  connect_bd_net -net interrupt_clock_irq [get_bd_pins irq] [get_bd_pins interrupt_clock/irq]
  connect_bd_net -net interrupt_clock_clk_base [get_bd_pins clk_base] [get_bd_pins interrupt_clock/clk_base]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_analog_adapter/A1_adapter
#   LTC2311 (8 canales, 1 master SPI) con IOBUFDS externo y averager
#   (promedio configurable por AXI GPIO: canales habilitados y n muestras).
# ---------------------------------------------------------------
proc create_hier_cell_A1_adapter { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_A1_adapter]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_pin -dir I -from 15 -to 0 A1_IN
  create_bd_pin -dir O -from 1 -to 0 A1_OUT_CLK
  create_bd_pin -dir O -from 0 -to 0 A1_OUT_CNV
  create_bd_pin -dir O -from 127 -to 0 ADC_VALUE
  create_bd_pin -dir O -from 0 -to 0 ADC_VALID
  create_bd_pin -dir I -from 0 -to 0 TRIGGER_CNV
  create_bd_pin -dir I clock_base_2sync
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst s00_axi_aresetn

  set A1_ADC_LTC2311 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_ADC_LTC2311:3.0 A1_ADC_LTC2311 ]
  set_property -dict [list \
    CONFIG.DIFFERENTIAL {false} \
    CONFIG.RES_LSB {0} \
    CONFIG.RES_MSB {34} \
    CONFIG.SPI_MASTER {1} \
  ] $A1_ADC_LTC2311

  set A1_inv_input [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 A1_inv_input ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0x0} \
    CONFIG.CONST_WIDTH {8} \
  ] $A1_inv_input

  set A1_iobufds_inst [ create_bd_cell -type ip -vlnv microzohm:user:MZ_IOBUFDS:1.0 A1_iobufds_inst ]

  set averager_mz_8ch_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_AVERAGER_8CH:1.0 averager_mz_8ch_0 ]
  # maximo de muestras a promediar = 2**MAX_AVG_LOG2 = 256 (n_datos_to_avg se redondea a potencia de 2);
  # dimensiona el acumulador (16 + MAX_AVG_LOG2 bits). main.c: MZ_AVERAGER_MAX_SAMPLES
  set_property CONFIG.MAX_AVG_LOG2 {8} $averager_mz_8ch_0

  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {32} \
    CONFIG.C_GPIO_WIDTH {8} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0

  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins A1_ADC_LTC2311/S00_AXI]

  connect_bd_net -net A1_ADC_LTC2311_RAW_VALUE [get_bd_pins A1_ADC_LTC2311/RAW_VALUE] [get_bd_pins averager_mz_8ch_0/datos_in_ch7_to_ch0]
  connect_bd_net -net A1_ADC_LTC2311_RAW_VALID [get_bd_pins ADC_VALID] [get_bd_pins A1_ADC_LTC2311/RAW_VALID] [get_bd_pins averager_mz_8ch_0/flag_new_datas]
  connect_bd_net -net A1_ADC_LTC2311_SCLK [get_bd_pins A1_ADC_LTC2311/SCLK] [get_bd_pins A1_iobufds_inst/SCLK_IN]
  connect_bd_net -net A1_ADC_LTC2311_SS_N [get_bd_pins A1_OUT_CNV] [get_bd_pins A1_ADC_LTC2311/SS_N]
  connect_bd_net -net A1_IN_1 [get_bd_pins A1_IN] [get_bd_pins A1_iobufds_inst/MISO_IN]
  connect_bd_net -net A1_iobufds_inst_MISO_OUT [get_bd_pins A1_ADC_LTC2311/MISO] [get_bd_pins A1_iobufds_inst/MISO_OUT]
  connect_bd_net -net A1_iobufds_inst_SCLK_OUT [get_bd_pins A1_OUT_CLK] [get_bd_pins A1_iobufds_inst/SCLK_OUT]
  connect_bd_net -net A1_inv_input_dout [get_bd_pins A1_inv_input/dout] [get_bd_pins A1_iobufds_inst/INVERT_OUTPUT]
  connect_bd_net -net TRIGGER_CNV_1 [get_bd_pins TRIGGER_CNV] [get_bd_pins A1_ADC_LTC2311/TRIGGER_CNV]
  connect_bd_net -net averager_mz_8ch_0_datos_out [get_bd_pins ADC_VALUE] [get_bd_pins averager_mz_8ch_0/datos_out_ch7_to_ch0]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins averager_mz_8ch_0/enable_chs] [get_bd_pins axi_gpio_0/gpio_io_o]
  connect_bd_net -net axi_gpio_0_gpio2_io_o [get_bd_pins averager_mz_8ch_0/n_datos_to_avg] [get_bd_pins axi_gpio_0/gpio2_io_o]
  connect_bd_net -net clock_base_2sync_1 [get_bd_pins clock_base_2sync] [get_bd_pins averager_mz_8ch_0/clock_base_2sync]
  connect_bd_net -net s00_axi_aresetn_1 [get_bd_pins s00_axi_aresetn] [get_bd_pins A1_ADC_LTC2311/s00_axi_aresetn] [get_bd_pins averager_mz_8ch_0/resetn] [get_bd_pins axi_gpio_0/s_axi_aresetn]
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins A1_ADC_LTC2311/s00_axi_aclk] [get_bd_pins averager_mz_8ch_0/clk] [get_bd_pins axi_gpio_0/s_axi_aclk]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_analog_adapter/A2_adapter
#   LTC2311 (8 canales) con IOBUFDS externo, sin averager.
# ---------------------------------------------------------------
proc create_hier_cell_A2_adapter { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_A2_adapter]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_pin -dir I -from 15 -to 0 A2_IN
  create_bd_pin -dir O -from 1 -to 0 A2_OUT_CLK
  create_bd_pin -dir O -from 0 -to 0 A2_OUT_CNV
  create_bd_pin -dir O -from 127 -to 0 ADC_VALUE
  create_bd_pin -dir I -from 0 -to 0 TRIGGER_CNV
  create_bd_pin -dir I -type clk s00_axi_aclk
  create_bd_pin -dir I -type rst s00_axi_aresetn

  set A2_ADC_LTC2311 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_ADC_LTC2311:3.0 A2_ADC_LTC2311 ]
  set_property -dict [list \
    CONFIG.DIFFERENTIAL {false} \
    CONFIG.RES_LSB {0} \
    CONFIG.RES_MSB {34} \
  ] $A2_ADC_LTC2311

  set A2_inv_input [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 A2_inv_input ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0x0} \
    CONFIG.CONST_WIDTH {8} \
  ] $A2_inv_input

  set A2_iobufds_inst [ create_bd_cell -type ip -vlnv microzohm:user:MZ_IOBUFDS:1.0 A2_iobufds_inst ]

  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins A2_ADC_LTC2311/S00_AXI]

  connect_bd_net -net A2_ADC_LTC2311_RAW_VALUE [get_bd_pins ADC_VALUE] [get_bd_pins A2_ADC_LTC2311/RAW_VALUE]
  connect_bd_net -net A2_ADC_LTC2311_SCLK [get_bd_pins A2_ADC_LTC2311/SCLK] [get_bd_pins A2_iobufds_inst/SCLK_IN]
  connect_bd_net -net A2_ADC_LTC2311_SS_N [get_bd_pins A2_OUT_CNV] [get_bd_pins A2_ADC_LTC2311/SS_N]
  connect_bd_net -net A2_IN_1 [get_bd_pins A2_IN] [get_bd_pins A2_iobufds_inst/MISO_IN]
  connect_bd_net -net A2_inv_input_dout [get_bd_pins A2_inv_input/dout] [get_bd_pins A2_iobufds_inst/INVERT_OUTPUT]
  connect_bd_net -net A2_iobufds_inst_MISO_OUT [get_bd_pins A2_ADC_LTC2311/MISO] [get_bd_pins A2_iobufds_inst/MISO_OUT]
  connect_bd_net -net A2_iobufds_inst_SCLK_OUT [get_bd_pins A2_OUT_CLK] [get_bd_pins A2_iobufds_inst/SCLK_OUT]
  connect_bd_net -net TRIGGER_CNV_1 [get_bd_pins TRIGGER_CNV] [get_bd_pins A2_ADC_LTC2311/TRIGGER_CNV]
  connect_bd_net -net s00_axi_aresetn_1 [get_bd_pins s00_axi_aresetn] [get_bd_pins A2_ADC_LTC2311/s00_axi_aresetn]
  connect_bd_net -net s00_axi_aclk_1 [get_bd_pins s00_axi_aclk] [get_bd_pins A2_ADC_LTC2311/s00_axi_aclk]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_analog_adapter/A3_adapter
#   MAX11331 (ADC lento, 16 canales single-ended). Solo hay un chip
#   conectado (miso[0]); el IP se configura para 6 como en el original.
# ---------------------------------------------------------------
proc create_hier_cell_A3_adapter { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_A3_adapter]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  create_bd_pin -dir I -from 0 -to 0 A3_IN
  create_bd_pin -dir O A3_OUT_CS
  create_bd_pin -dir O A3_OUT_MOSI
  create_bd_pin -dir O A3_OUT_SCLK
  create_bd_pin -dir O -from 255 -to 0 ADC_VALUE
  create_bd_pin -dir I enable_measure
  create_bd_pin -dir I -type clk s00_axi_aclk
  create_bd_pin -dir I -type rst s00_axi_aresetn

  set ADC_MAX11331_top_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_ADC_MAX11331:1.0 ADC_MAX11331_top_0 ]
  set_property CONFIG.NUMBER_OF_ADCS {6} $ADC_MAX11331_top_0

  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {16} $xlconcat_0

  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]

  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {5} \
  ] $xlconstant_0

  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins ADC_MAX11331_top_0/s_axi_lite]

  connect_bd_net -net A3_IN_1 [get_bd_pins A3_IN] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconcat_1/In1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins ADC_MAX11331_top_0/miso] [get_bd_pins xlconcat_1/dout]
  for {set i 0} {$i < 16} {incr i} {
    connect_bd_net -net ADC_MAX11331_top_0_ch$i [get_bd_pins ADC_MAX11331_top_0/ch$i] [get_bd_pins xlconcat_0/In$i]
  }
  connect_bd_net -net xlconcat_0_dout [get_bd_pins ADC_VALUE] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net ADC_MAX11331_top_0_mosi [get_bd_pins A3_OUT_MOSI] [get_bd_pins ADC_MAX11331_top_0/mosi]
  connect_bd_net -net ADC_MAX11331_top_0_sclk [get_bd_pins A3_OUT_SCLK] [get_bd_pins ADC_MAX11331_top_0/sclk]
  connect_bd_net -net ADC_MAX11331_top_0_ss_n [get_bd_pins A3_OUT_CS] [get_bd_pins ADC_MAX11331_top_0/ss_n]
  connect_bd_net -net enable_measure_1 [get_bd_pins enable_measure] [get_bd_pins ADC_MAX11331_top_0/enable_measure]
  connect_bd_net -net s00_axi_aresetn_1 [get_bd_pins s00_axi_aresetn] [get_bd_pins ADC_MAX11331_top_0/reset_n] [get_bd_pins ADC_MAX11331_top_0/s_axi_lite_aresetn]
  connect_bd_net -net s00_axi_aclk_1 [get_bd_pins s00_axi_aclk] [get_bd_pins ADC_MAX11331_top_0/clk] [get_bd_pins ADC_MAX11331_top_0/s_axi_lite_aclk]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_analog_adapter
# ---------------------------------------------------------------
proc create_hier_cell_mz_analog_adapter { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_mz_analog_adapter]
  if { $hier_obj eq "" } { return }

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_A1_ADC
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_A2_ADC
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_A3_ADC
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_A1_GPIO
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CLOCK_FLAG_DIV

  create_bd_pin -dir I -from 15 -to 0 A1_IN
  create_bd_pin -dir O -from 1 -to 0 A1_OUT_CLK
  create_bd_pin -dir O -from 0 -to 0 A1_OUT_CNV
  create_bd_pin -dir I -from 15 -to 0 A2_IN
  create_bd_pin -dir O -from 1 -to 0 A2_OUT_CLK
  create_bd_pin -dir O -from 0 -to 0 A2_OUT_CNV
  create_bd_pin -dir I -from 0 -to 0 A3_IN
  create_bd_pin -dir O A3_OUT_CS
  create_bd_pin -dir O A3_OUT_MOSI
  create_bd_pin -dir O A3_OUT_SCLK
  # Hacia el PS (DataMover -> S_AXI_LPD)
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_LPD
  create_bd_pin -dir I -type clk clk_base
  create_bd_pin -dir I clock_base_2sync
  create_bd_pin -dir I -from 0 -to 0 ENABLE_AXI2TCM
  create_bd_pin -dir I -type clk s00_axi_aclk
  create_bd_pin -dir I -type rst s00_axi_aresetn

  create_hier_cell_A1_adapter $hier_obj A1_adapter
  create_hier_cell_A2_adapter $hier_obj A2_adapter
  create_hier_cell_A3_adapter $hier_obj A3_adapter

  # Trigger de conversion de A1/A2: divide el reloj base de la interrupcion (clk_base) y arranca
  # sincronizado con el ISR (clock_base_2sync). f_ADC = f_base / MAX. El trigger es clk_output
  # (onda cuadrada) para que el LTC2311, a 100 MHz, nunca pierda un flanco.
  set clock_flag_div_axi_mz_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_CLOCK_FLAG_DIV:1.0 clock_flag_div_axi_mz_0 ]

  # DataMover: copia los 32 valores de ADC a la TCM del R5 cada vez que A1 entrega datos validos
  create_hier_cell_DataMover $hier_obj DataMover

  connect_bd_intf_net -intf_net S_AXI_A1_ADC_1  [get_bd_intf_pins S_AXI_A1_ADC]  [get_bd_intf_pins A1_adapter/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_A2_ADC_1  [get_bd_intf_pins S_AXI_A2_ADC]  [get_bd_intf_pins A2_adapter/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_A3_ADC_1  [get_bd_intf_pins S_AXI_A3_ADC]  [get_bd_intf_pins A3_adapter/S00_AXI]
  connect_bd_intf_net -intf_net S_AXI_A1_GPIO_1 [get_bd_intf_pins S_AXI_A1_GPIO] [get_bd_intf_pins A1_adapter/S_AXI]
  connect_bd_intf_net -intf_net S_AXI_CLOCK_FLAG_DIV_1 [get_bd_intf_pins S_AXI_CLOCK_FLAG_DIV] [get_bd_intf_pins clock_flag_div_axi_mz_0/s00_axi]
  connect_bd_intf_net -intf_net DataMover_M00_AXI [get_bd_intf_pins M_AXI_LPD] [get_bd_intf_pins DataMover/M00_AXI]

  connect_bd_net -net A1_IN_1 [get_bd_pins A1_IN] [get_bd_pins A1_adapter/A1_IN]
  connect_bd_net -net A1_adapter_A1_OUT_CLK [get_bd_pins A1_OUT_CLK] [get_bd_pins A1_adapter/A1_OUT_CLK]
  connect_bd_net -net A1_adapter_A1_OUT_CNV [get_bd_pins A1_OUT_CNV] [get_bd_pins A1_adapter/A1_OUT_CNV]
  connect_bd_net -net A1_adapter_ADC_VALUE [get_bd_pins A1_adapter/ADC_VALUE] [get_bd_pins DataMover/ADC_A1]
  connect_bd_net -net A1_adapter_ADC_VALID [get_bd_pins A1_adapter/ADC_VALID] [get_bd_pins DataMover/Trigger_AXI2TCM]
  connect_bd_net -net A2_IN_1 [get_bd_pins A2_IN] [get_bd_pins A2_adapter/A2_IN]
  connect_bd_net -net A2_adapter_A2_OUT_CLK [get_bd_pins A2_OUT_CLK] [get_bd_pins A2_adapter/A2_OUT_CLK]
  connect_bd_net -net A2_adapter_A2_OUT_CNV [get_bd_pins A2_OUT_CNV] [get_bd_pins A2_adapter/A2_OUT_CNV]
  connect_bd_net -net A2_adapter_ADC_VALUE [get_bd_pins A2_adapter/ADC_VALUE] [get_bd_pins DataMover/ADC_A2]
  connect_bd_net -net A3_IN_1 [get_bd_pins A3_IN] [get_bd_pins A3_adapter/A3_IN]
  connect_bd_net -net A3_adapter_A3_OUT_CS [get_bd_pins A3_OUT_CS] [get_bd_pins A3_adapter/A3_OUT_CS]
  connect_bd_net -net A3_adapter_A3_OUT_MOSI [get_bd_pins A3_OUT_MOSI] [get_bd_pins A3_adapter/A3_OUT_MOSI]
  connect_bd_net -net A3_adapter_A3_OUT_SCLK [get_bd_pins A3_OUT_SCLK] [get_bd_pins A3_adapter/A3_OUT_SCLK]
  connect_bd_net -net A3_adapter_ADC_VALUE [get_bd_pins A3_adapter/ADC_VALUE] [get_bd_pins DataMover/ADC_A3]
  connect_bd_net -net clock_flag_div_clk_output [get_bd_pins clock_flag_div_axi_mz_0/clk_output] [get_bd_pins A1_adapter/TRIGGER_CNV] [get_bd_pins A2_adapter/TRIGGER_CNV]
  connect_bd_net -net clk_base_1 [get_bd_pins clk_base] [get_bd_pins clock_flag_div_axi_mz_0/clk]
  connect_bd_net -net clock_base_2sync_1 [get_bd_pins clock_base_2sync] [get_bd_pins A1_adapter/clock_base_2sync] [get_bd_pins clock_flag_div_axi_mz_0/clock_base_2sync]
  connect_bd_net -net ENABLE_AXI2TCM_1 [get_bd_pins ENABLE_AXI2TCM] [get_bd_pins A3_adapter/enable_measure] [get_bd_pins DataMover/ENABLE_AXI2TCM]
  connect_bd_net -net s00_axi_aresetn_1 [get_bd_pins s00_axi_aresetn] [get_bd_pins A1_adapter/s00_axi_aresetn] [get_bd_pins A2_adapter/s00_axi_aresetn] [get_bd_pins A3_adapter/s00_axi_aresetn] [get_bd_pins clock_flag_div_axi_mz_0/s00_axi_aresetn] [get_bd_pins DataMover/m00_axi_aresetn]
  connect_bd_net -net s00_axi_aclk_1 [get_bd_pins s00_axi_aclk] [get_bd_pins A1_adapter/clk] [get_bd_pins A2_adapter/s00_axi_aclk] [get_bd_pins A3_adapter/s00_axi_aclk] [get_bd_pins clock_flag_div_axi_mz_0/s00_axi_aclk] [get_bd_pins DataMover/m00_axi_aclk]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Hierarchical cell: mz_digital_adapter
#   Mapeo de las salidas de AXI_PWM_0 al conector digital D1 (24 bits,
#   salida invertida). Misma asignacion de bits que el proyecto original:
#     D1_OUT[1]=G1  [2]=square  [3]=G2  [13]=G3  [15]=G4  [21]=enable
#   El resto de bits queda a 0 (=> '1' tras la inversion).
# ---------------------------------------------------------------
proc create_hier_cell_mz_digital_adapter { parentCell nameHier } {
  set oldCurInst [current_bd_instance .]
  set hier_obj [_hier_begin $parentCell $nameHier create_hier_cell_mz_digital_adapter]
  if { $hier_obj eq "" } { return }

  create_bd_pin -dir I G1
  create_bd_pin -dir I G2
  create_bd_pin -dir I G3
  create_bd_pin -dir I G4
  create_bd_pin -dir I square
  create_bd_pin -dir I enable
  create_bd_pin -dir O -from 23 -to 0 D1_OUT

  set D1_gates_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 D1_gates_concat ]
  set_property -dict [list \
    CONFIG.NUM_PORTS {11} \
    CONFIG.IN0_WIDTH {1} \
    CONFIG.IN1_WIDTH {1} \
    CONFIG.IN2_WIDTH {1} \
    CONFIG.IN3_WIDTH {1} \
    CONFIG.IN4_WIDTH {9} \
    CONFIG.IN5_WIDTH {1} \
    CONFIG.IN6_WIDTH {1} \
    CONFIG.IN7_WIDTH {1} \
    CONFIG.IN8_WIDTH {5} \
    CONFIG.IN9_WIDTH {1} \
    CONFIG.IN10_WIDTH {2} \
  ] $D1_gates_concat

  set D1_invert [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 D1_invert ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {24} \
  ] $D1_invert

  set zero_1bit [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 zero_1bit ]
  set_property CONFIG.CONST_VAL {0} $zero_1bit
  set zero_9bit [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 zero_9bit ]
  set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {9}] $zero_9bit
  set zero_5bit [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 zero_5bit ]
  set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {5}] $zero_5bit
  set zero_2bit [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 zero_2bit ]
  set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {2}] $zero_2bit

  connect_bd_net -net G1_1     [get_bd_pins G1]     [get_bd_pins D1_gates_concat/In1]
  connect_bd_net -net square_1 [get_bd_pins square] [get_bd_pins D1_gates_concat/In2]
  connect_bd_net -net G2_1     [get_bd_pins G2]     [get_bd_pins D1_gates_concat/In3]
  connect_bd_net -net G3_1     [get_bd_pins G3]     [get_bd_pins D1_gates_concat/In5]
  connect_bd_net -net G4_1     [get_bd_pins G4]     [get_bd_pins D1_gates_concat/In7]
  connect_bd_net -net enable_1 [get_bd_pins enable] [get_bd_pins D1_gates_concat/In9]
  connect_bd_net -net zero_1bit_dout [get_bd_pins zero_1bit/dout] [get_bd_pins D1_gates_concat/In0] [get_bd_pins D1_gates_concat/In6]
  connect_bd_net -net zero_9bit_dout [get_bd_pins zero_9bit/dout] [get_bd_pins D1_gates_concat/In4]
  connect_bd_net -net zero_5bit_dout [get_bd_pins zero_5bit/dout] [get_bd_pins D1_gates_concat/In8]
  connect_bd_net -net zero_2bit_dout [get_bd_pins zero_2bit/dout] [get_bd_pins D1_gates_concat/In10]
  connect_bd_net -net D1_gates_concat_dout [get_bd_pins D1_gates_concat/dout] [get_bd_pins D1_invert/Op1]
  connect_bd_net -net D1_invert_Res [get_bd_pins D1_OUT] [get_bd_pins D1_invert/Res]

  current_bd_instance $oldCurInst
}


# ---------------------------------------------------------------
# Root design
# ---------------------------------------------------------------
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }
  set oldCurInst [current_bd_instance .]
  current_bd_instance $parentObj

  # ---- Puertos externos (mismos nombres que las constraints) ----
  set A1_IN        [ create_bd_port -dir I -from 15 -to 0 A1_IN ]
  set A1_OUT_CLK   [ create_bd_port -dir O -from 1 -to 0 A1_OUT_CLK ]
  set A1_OUT_CNV_0 [ create_bd_port -dir O -from 0 -to 0 A1_OUT_CNV_0 ]
  set A1_OUT_CNV_1 [ create_bd_port -dir O -from 0 -to 0 A1_OUT_CNV_1 ]
  set A2_IN        [ create_bd_port -dir I -from 15 -to 0 A2_IN ]
  set A2_OUT_CLK   [ create_bd_port -dir O -from 1 -to 0 A2_OUT_CLK ]
  set A2_OUT_CNV_0 [ create_bd_port -dir O -from 0 -to 0 A2_OUT_CNV_0 ]
  set A2_OUT_CNV_1 [ create_bd_port -dir O -from 0 -to 0 A2_OUT_CNV_1 ]
  set A3_IN   [ create_bd_port -dir I -from 0 -to 0 A3_IN ]
  set A3_OUT_CS    [ create_bd_port -dir O -from 0 -to 0 A3_OUT_CS ]
  set A3_OUT_MOSI  [ create_bd_port -dir O -from 0 -to 0 A3_OUT_MOSI ]
  set A3_OUT_SCLK  [ create_bd_port -dir O -from 0 -to 0 A3_OUT_SCLK ]
  set D1_OUT       [ create_bd_port -dir O -from 23 -to 0 D1_OUT ]
  set D2_IN_PHASE  [ create_bd_port -dir I D2_IN_PHASE ]
  # Patron de habilitacion del Safety CPLD en los cuatro conectores digitales
  foreach d {D1 D2 D3 D4} {
    foreach b {26 27 28 29} {
      create_bd_port -dir O -from 0 -to 0 ${d}_OUT_${b}
    }
  }

  # ---- Celdas de nivel superior ----
  set AXI_PHASE_DETECTOR_v_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_AXI_PHASE_DETECTOR:1.0 AXI_PHASE_DETECTOR_v_0 ]
  set AXI_PWM_0 [ create_bd_cell -type ip -vlnv microzohm:user:MZ_AXI_PWM:1.0 AXI_PWM_0 ]

  create_hier_cell_mz_analog_adapter  [current_bd_instance .] mz_analog_adapter
  create_hier_cell_mz_digital_adapter [current_bd_instance .] mz_digital_adapter
  create_hier_cell_mz_system          [current_bd_instance .] mz_system

  # ---- Processing System (configuracion identica al proyecto original) ----
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0 ]
  set_property -dict [list \
    CONFIG.CAN0_BOARD_INTERFACE {custom} \
    CONFIG.CAN1_BOARD_INTERFACE {custom} \
    CONFIG.CSU_BOARD_INTERFACE {custom} \
    CONFIG.DP_BOARD_INTERFACE {custom} \
    CONFIG.GEM0_BOARD_INTERFACE {custom} \
    CONFIG.GEM1_BOARD_INTERFACE {custom} \
    CONFIG.GEM2_BOARD_INTERFACE {custom} \
    CONFIG.GEM3_BOARD_INTERFACE {custom} \
    CONFIG.GPIO_BOARD_INTERFACE {custom} \
    CONFIG.IIC0_BOARD_INTERFACE {custom} \
    CONFIG.IIC1_BOARD_INTERFACE {custom} \
    CONFIG.NAND_BOARD_INTERFACE {custom} \
    CONFIG.PCIE_BOARD_INTERFACE {custom} \
    CONFIG.PJTAG_BOARD_INTERFACE {custom} \
    CONFIG.PMU_BOARD_INTERFACE {custom} \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_DDR_RAM_HIGHADDR {0x7FFFFFFF} \
    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x00000002} \
    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
    CONFIG.PSU_MIO_0_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_0_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_0_SLEW {slow} \
    CONFIG.PSU_MIO_10_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_10_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_10_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_10_SLEW {slow} \
    CONFIG.PSU_MIO_11_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_11_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_11_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_11_SLEW {slow} \
    CONFIG.PSU_MIO_12_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_12_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_12_SLEW {slow} \
    CONFIG.PSU_MIO_13_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_13_POLARITY {Default} \
    CONFIG.PSU_MIO_13_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_13_SLEW {slow} \
    CONFIG.PSU_MIO_14_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_14_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_14_POLARITY {Default} \
    CONFIG.PSU_MIO_14_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_14_SLEW {slow} \
    CONFIG.PSU_MIO_15_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_15_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_15_POLARITY {Default} \
    CONFIG.PSU_MIO_15_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_15_SLEW {slow} \
    CONFIG.PSU_MIO_16_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_16_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_16_POLARITY {Default} \
    CONFIG.PSU_MIO_16_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_16_SLEW {slow} \
    CONFIG.PSU_MIO_17_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_17_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_17_POLARITY {Default} \
    CONFIG.PSU_MIO_17_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_17_SLEW {slow} \
    CONFIG.PSU_MIO_18_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_18_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_19_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_19_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_19_SLEW {slow} \
    CONFIG.PSU_MIO_1_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_1_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_1_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_1_SLEW {slow} \
    CONFIG.PSU_MIO_20_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_20_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_20_POLARITY {Default} \
    CONFIG.PSU_MIO_20_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_20_SLEW {slow} \
    CONFIG.PSU_MIO_21_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_21_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_21_POLARITY {Default} \
    CONFIG.PSU_MIO_21_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_21_SLEW {fast} \
    CONFIG.PSU_MIO_22_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_22_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_22_POLARITY {Default} \
    CONFIG.PSU_MIO_22_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_22_SLEW {fast} \
    CONFIG.PSU_MIO_23_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_23_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_23_POLARITY {Default} \
    CONFIG.PSU_MIO_23_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_23_SLEW {slow} \
    CONFIG.PSU_MIO_24_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_24_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_24_SLEW {slow} \
    CONFIG.PSU_MIO_25_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_25_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_26_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_26_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_27_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_27_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_28_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_28_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_28_SLEW {slow} \
    CONFIG.PSU_MIO_29_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_29_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_2_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_2_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_2_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_2_SLEW {slow} \
    CONFIG.PSU_MIO_30_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_30_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_31_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_31_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_31_SLEW {slow} \
    CONFIG.PSU_MIO_32_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_32_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_32_SLEW {slow} \
    CONFIG.PSU_MIO_33_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_33_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_33_SLEW {slow} \
    CONFIG.PSU_MIO_34_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_34_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_34_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_34_SLEW {slow} \
    CONFIG.PSU_MIO_35_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_35_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_35_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_35_SLEW {slow} \
    CONFIG.PSU_MIO_36_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_36_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_36_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_36_SLEW {slow} \
    CONFIG.PSU_MIO_37_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_37_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_37_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_37_SLEW {slow} \
    CONFIG.PSU_MIO_38_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_38_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_38_SLEW {slow} \
    CONFIG.PSU_MIO_39_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_39_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_39_SLEW {slow} \
    CONFIG.PSU_MIO_3_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_3_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_3_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_3_SLEW {slow} \
    CONFIG.PSU_MIO_40_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_40_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_40_SLEW {slow} \
    CONFIG.PSU_MIO_41_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_41_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_41_SLEW {slow} \
    CONFIG.PSU_MIO_42_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_42_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_42_SLEW {fast} \
    CONFIG.PSU_MIO_43_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_43_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_43_SLEW {slow} \
    CONFIG.PSU_MIO_44_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_44_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_45_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_45_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_46_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_46_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_47_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_47_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_48_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_48_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_49_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_49_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_4_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_4_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_4_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_4_SLEW {slow} \
    CONFIG.PSU_MIO_50_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_50_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_50_SLEW {slow} \
    CONFIG.PSU_MIO_51_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_51_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_51_PULLUPDOWN {disable} \
    CONFIG.PSU_MIO_51_SLEW {slow} \
    CONFIG.PSU_MIO_52_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_52_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_52_SLEW {slow} \
    CONFIG.PSU_MIO_53_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_53_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_53_SLEW {slow} \
    CONFIG.PSU_MIO_54_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_54_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_54_SLEW {slow} \
    CONFIG.PSU_MIO_55_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_55_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_55_SLEW {slow} \
    CONFIG.PSU_MIO_56_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_56_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_56_SLEW {slow} \
    CONFIG.PSU_MIO_57_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_57_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_57_SLEW {slow} \
    CONFIG.PSU_MIO_58_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_58_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_59_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_59_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_5_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_5_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_5_SLEW {slow} \
    CONFIG.PSU_MIO_60_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_60_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_61_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_61_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_62_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_62_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_63_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_63_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_64_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_64_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_64_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_64_SLEW {slow} \
    CONFIG.PSU_MIO_65_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_65_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_65_SLEW {slow} \
    CONFIG.PSU_MIO_66_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_66_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_66_SLEW {slow} \
    CONFIG.PSU_MIO_67_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_67_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_67_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_67_SLEW {slow} \
    CONFIG.PSU_MIO_68_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_68_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_68_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_68_SLEW {slow} \
    CONFIG.PSU_MIO_69_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_69_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_69_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_69_SLEW {slow} \
    CONFIG.PSU_MIO_6_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_6_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_6_SLEW {slow} \
    CONFIG.PSU_MIO_70_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_70_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_70_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_70_SLEW {fast} \
    CONFIG.PSU_MIO_71_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_71_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_71_SLEW {fast} \
    CONFIG.PSU_MIO_72_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_72_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_72_SLEW {fast} \
    CONFIG.PSU_MIO_73_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_73_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_73_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_73_SLEW {fast} \
    CONFIG.PSU_MIO_74_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_74_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_74_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_74_SLEW {fast} \
    CONFIG.PSU_MIO_75_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_75_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_75_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_75_SLEW {fast} \
    CONFIG.PSU_MIO_76_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_76_POLARITY {Default} \
    CONFIG.PSU_MIO_76_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_76_SLEW {slow} \
    CONFIG.PSU_MIO_77_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_77_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_77_POLARITY {Default} \
    CONFIG.PSU_MIO_77_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_77_SLEW {slow} \
    CONFIG.PSU_MIO_7_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_7_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_7_SLEW {slow} \
    CONFIG.PSU_MIO_8_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_8_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_8_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_8_SLEW {slow} \
    CONFIG.PSU_MIO_9_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_9_INPUT_TYPE {schmitt} \
    CONFIG.PSU_MIO_9_PULLUPDOWN {pullup} \
    CONFIG.PSU_MIO_9_SLEW {slow} \
    CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Feedback Clk#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad\
SPI Flash#Quad SPI Flash#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#UART 0#UART 0#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#GPIO0 MIO#CAN 1#CAN 1#PMU GPI 0#PMU GPI 1#UART 1#UART 1#CAN 0#CAN 0#PMU GPO 0#PMU\
GPO 1#I2C 0#I2C 0#I2C 1#I2C 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#Gem 1#MDIO 1#MDIO 1#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#Gem 2#SPI 0#SPI 0#SPI\
0#SPI 0#SPI 0#SPI 0#SPI 1#SPI 1#SPI 1#SPI 1#SPI 1#SPI 1#GPIO2 MIO#GPIO2 MIO} \
    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#clk_for_lpbk#n_ss_out_upper#mo_upper[0]#mo_upper[1]#mo_upper[2]#mo_upper[3]#sclk_out_upper#gpio0[13]#gpio0[14]#gpio0[15]#gpio0[16]#gpio0[17]#rxd#txd#gpio0[20]#gpio0[21]#gpio0[22]#gpio0[23]#phy_tx#phy_rx#gpi[0]#gpi[1]#txd#rxd#phy_rx#phy_tx#gpo[0]#gpo[1]#scl_out#sda_out#scl_out#sda_out#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem1_mdc#gem1_mdio_out#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#sclk_out#n_ss_out[2]#n_ss_out[1]#n_ss_out[0]#miso#mosi#sclk_out#n_ss_out[2]#n_ss_out[1]#n_ss_out[0]#miso#mosi#gpio2[76]#gpio2[77]}\
\
    CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {8} \
    CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {4} \
    CONFIG.PSU_SMC_CYCLE_T0 {NA} \
    CONFIG.PSU_SMC_CYCLE_T1 {NA} \
    CONFIG.PSU_SMC_CYCLE_T2 {NA} \
    CONFIG.PSU_SMC_CYCLE_T3 {NA} \
    CONFIG.PSU_SMC_CYCLE_T4 {NA} \
    CONFIG.PSU_SMC_CYCLE_T5 {NA} \
    CONFIG.PSU_SMC_CYCLE_T6 {NA} \
    CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {0} \
    CONFIG.PSU_VALUE_SILVERSION {3} \
    CONFIG.PSU__ACPU0__POWER__ON {1} \
    CONFIG.PSU__ACPU1__POWER__ON {1} \
    CONFIG.PSU__ACPU2__POWER__ON {1} \
    CONFIG.PSU__ACPU3__POWER__ON {1} \
    CONFIG.PSU__ACTUAL__IP {1} \
    CONFIG.PSU__ACT_DDR_FREQ_MHZ {1200.000000} \
    CONFIG.PSU__AUX_REF_CLK__FREQMHZ {33.333} \
    CONFIG.PSU__CAN0_LOOP_CAN1__ENABLE {0} \
    CONFIG.PSU__CAN0__GRP_CLK__ENABLE {0} \
    CONFIG.PSU__CAN0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__CAN0__PERIPHERAL__IO {MIO 30 .. 31} \
    CONFIG.PSU__CAN1__GRP_CLK__ENABLE {0} \
    CONFIG.PSU__CAN1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__CAN1__PERIPHERAL__IO {MIO 24 .. 25} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1050.000000} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__ACPU__FRAC_ENABLED {0} \
    CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI0_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI0_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI1_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI1_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI2_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI2_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI3_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI3_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI4_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI4_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__ACT_FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__DIVISOR0 {2} \
    CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__FREQMHZ {667} \
    CONFIG.PSU__CRF_APB__AFI5_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__AFI5_REF__ENABLE {0} \
    CONFIG.PSU__CRF_APB__APLL_CTRL__FRACFREQ {27.138} \
    CONFIG.PSU__CRF_APB__APLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__APM_CTRL__ACT_FREQMHZ {1} \
    CONFIG.PSU__CRF_APB__APM_CTRL__DIVISOR0 {1} \
    CONFIG.PSU__CRF_APB__APM_CTRL__FREQMHZ {1} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__ACT_FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACFREQ {27.138} \
    CONFIG.PSU__CRF_APB__DPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__ACT_FREQMHZ {25} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__FREQMHZ {25} \
    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {VPLL} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__ACT_FREQMHZ {26.786} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__FREQMHZ {27} \
    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {VPLL} \
    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__ACT_FREQMHZ {300.000} \
    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__FREQMHZ {300} \
    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {600.000000} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__FREQMHZ {600} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__ACT_FREQMHZ {-1} \
    CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__DIVISOR0 {-1} \
    CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__FREQMHZ {-1} \
    CONFIG.PSU__CRF_APB__GTGREF0_REF_CTRL__SRCSEL {NA} \
    CONFIG.PSU__CRF_APB__GTGREF0__ENABLE {NA} \
    CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__ACT_FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {525.000000} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__FREQMHZ {533.333} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {APLL} \
    CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACFREQ {27.138} \
    CONFIG.PSU__CRF_APB__VPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {500.000000} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__ACT_FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__AFI6__ENABLE {0} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {50.000000} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__FREQMHZ {50} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {500.000000} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__ACT_FREQMHZ {180} \
    CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__DIVISOR0 {3} \
    CONFIG.PSU__CRL_APB__CSU_PLL_CTRL__SRCSEL {SysOsc} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__ACT_FREQMHZ {1000} \
    CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__DIVISOR0 {6} \
    CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__FREQMHZ {1000} \
    CONFIG.PSU__CRL_APB__DEBUG_R5_ATCLK_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1500.000000} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__FREQMHZ {1500} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__ACT_FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__ACT_FREQMHZ {125.000000} \
    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__ACT_FREQMHZ {125.000000} \
    CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__ACT_FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__FREQMHZ {125} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {250.000000} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACFREQ {27.138} \
    CONFIG.PSU__CRL_APB__IOPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {266.666656} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__FREQMHZ {267} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {500.000000} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__NAND_REF_CTRL__ACT_FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__NAND_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__NAND_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__ACT_FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__DIVISOR0 {3} \
    CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__FREQMHZ {500} \
    CONFIG.PSU__CRL_APB__OCM_MAIN_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.500000} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ {9.999998} \
    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ {49.999992} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {300.000000} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__FREQMHZ {300} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACFREQ {27.138} \
    CONFIG.PSU__CRL_APB__RPLL_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__ACT_FREQMHZ {200.000000} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__ACT_FREQMHZ {200.000000} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {33.333332} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__SRCSEL {PSS_REF_CLK} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__ACT_FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {20} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__FREQMHZ {20} \
    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__USB3__ENABLE {0} \
    CONFIG.PSU__CSUPMU__PERIPHERAL__VALID {1} \
    CONFIG.PSU__CSU__CSU_TAMPER_0__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_10__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_11__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_12__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_1__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_2__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_3__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_4__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_5__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_6__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_7__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_8__ENABLE {0} \
    CONFIG.PSU__CSU__CSU_TAMPER_9__ENABLE {0} \
    CONFIG.PSU__CSU__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__DDRC__AL {0} \
    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__BRC_MAPPING {ROW_BANK_COL} \
    CONFIG.PSU__DDRC__BUS_WIDTH {64 Bit} \
    CONFIG.PSU__DDRC__CL {17} \
    CONFIG.PSU__DDRC__CLOCK_STOP_EN {0} \
    CONFIG.PSU__DDRC__COMPONENTS {Components} \
    CONFIG.PSU__DDRC__CWL {16} \
    CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING {1} \
    CONFIG.PSU__DDRC__DDR4_CAL_MODE_ENABLE {0} \
    CONFIG.PSU__DDRC__DDR4_CRC_CONTROL {0} \
    CONFIG.PSU__DDRC__DDR4_MAXPWR_SAVING_EN {0} \
    CONFIG.PSU__DDRC__DDR4_T_REF_MODE {1} \
    CONFIG.PSU__DDRC__DDR4_T_REF_RANGE {Normal (0-85)} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {4096 MBits} \
    CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
    CONFIG.PSU__DDRC__ECC {Disabled} \
    CONFIG.PSU__DDRC__ECC_SCRUB {0} \
    CONFIG.PSU__DDRC__ENABLE {1} \
    CONFIG.PSU__DDRC__ENABLE_2T_TIMING {0} \
    CONFIG.PSU__DDRC__ENABLE_DP_SWITCH {0} \
    CONFIG.PSU__DDRC__EN_2ND_CLK {0} \
    CONFIG.PSU__DDRC__FREQ_MHZ {1} \
    CONFIG.PSU__DDRC__LPDDR3_DUALRANK_SDP {0} \
    CONFIG.PSU__DDRC__LP_ASR {manual normal} \
    CONFIG.PSU__DDRC__MEMORY_TYPE {DDR 4} \
    CONFIG.PSU__DDRC__PARITY_ENABLE {0} \
    CONFIG.PSU__DDRC__PER_BANK_REFRESH {0} \
    CONFIG.PSU__DDRC__PHY_DBI_MODE {0} \
    CONFIG.PSU__DDRC__PLL_BYPASS {0} \
    CONFIG.PSU__DDRC__PWR_DOWN_EN {0} \
    CONFIG.PSU__DDRC__RANK_ADDR_COUNT {0} \
    CONFIG.PSU__DDRC__RD_DQS_CENTER {0} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {15} \
    CONFIG.PSU__DDRC__SELF_REF_ABORT {0} \
    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400R} \
    CONFIG.PSU__DDRC__STATIC_RD_MODE {0} \
    CONFIG.PSU__DDRC__TRAIN_DATA_EYE {1} \
    CONFIG.PSU__DDRC__TRAIN_READ_GATE {1} \
    CONFIG.PSU__DDRC__TRAIN_WRITE_LEVEL {1} \
    CONFIG.PSU__DDRC__T_FAW {30.0} \
    CONFIG.PSU__DDRC__T_RAS_MIN {32.0} \
    CONFIG.PSU__DDRC__T_RC {50} \
    CONFIG.PSU__DDRC__T_RCD {17} \
    CONFIG.PSU__DDRC__T_RP {17} \
    CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE {0} \
    CONFIG.PSU__DDRC__VREF {1} \
    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {0} \
    CONFIG.PSU__DDR_QOS_ENABLE {0} \
    CONFIG.PSU__DDR_QOS_HP1_RDQOS {} \
    CONFIG.PSU__DDR_QOS_HP1_WRQOS {} \
    CONFIG.PSU__DDR_QOS_HP2_RDQOS {} \
    CONFIG.PSU__DDR_QOS_HP2_WRQOS {} \
    CONFIG.PSU__DDR_QOS_HP3_RDQOS {} \
    CONFIG.PSU__DDR_SW_REFRESH_ENABLED {0} \
    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
    CONFIG.PSU__DEVICE_TYPE {EG} \
    CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__DLL__ISUSED {0} \
    CONFIG.PSU__ENABLE__DDR__REFRESH__SIGNALS {0} \
    CONFIG.PSU__ENET0__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__ENET1__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET1__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET1__GRP_MDIO__IO {MIO 50 .. 51} \
    CONFIG.PSU__ENET1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET1__PERIPHERAL__IO {MIO 38 .. 49} \
    CONFIG.PSU__ENET1__PTP__ENABLE {0} \
    CONFIG.PSU__ENET1__TSU__ENABLE {0} \
    CONFIG.PSU__ENET2__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET2__GRP_MDIO__ENABLE {0} \
    CONFIG.PSU__ENET2__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET2__PERIPHERAL__IO {MIO 52 .. 63} \
    CONFIG.PSU__ENET2__PTP__ENABLE {0} \
    CONFIG.PSU__ENET2__TSU__ENABLE {0} \
    CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__EN_AXI_STATUS_PORTS {0} \
    CONFIG.PSU__EN_EMIO_TRACE {0} \
    CONFIG.PSU__EP__IP {0} \
    CONFIG.PSU__EXPAND__CORESIGHT {0} \
    CONFIG.PSU__EXPAND__FPD_SLAVES {0} \
    CONFIG.PSU__EXPAND__GIC {0} \
    CONFIG.PSU__EXPAND__LOWER_LPS_SLAVES {0} \
    CONFIG.PSU__EXPAND__UPPER_LPS_SLAVES {0} \
    CONFIG.PSU__FPDMASTERS_COHERENCY {0} \
    CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__FPGA_PL1_ENABLE {0} \
    CONFIG.PSU__FPGA_PL2_ENABLE {0} \
    CONFIG.PSU__FPGA_PL3_ENABLE {0} \
    CONFIG.PSU__FP__POWER__ON {1} \
    CONFIG.PSU__FTM__CTI_IN_0 {0} \
    CONFIG.PSU__FTM__CTI_IN_1 {0} \
    CONFIG.PSU__FTM__CTI_IN_2 {0} \
    CONFIG.PSU__FTM__CTI_IN_3 {0} \
    CONFIG.PSU__FTM__CTI_OUT_0 {0} \
    CONFIG.PSU__FTM__CTI_OUT_1 {0} \
    CONFIG.PSU__FTM__CTI_OUT_2 {0} \
    CONFIG.PSU__FTM__CTI_OUT_3 {0} \
    CONFIG.PSU__FTM__GPI {0} \
    CONFIG.PSU__FTM__GPO {0} \
    CONFIG.PSU__GEM1_COHERENCY {0} \
    CONFIG.PSU__GEM1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM2_COHERENCY {0} \
    CONFIG.PSU__GEM2_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM__TSU__ENABLE {0} \
    CONFIG.PSU__GEN_IPI_0__MASTER {APU} \
    CONFIG.PSU__GEN_IPI_10__MASTER {NONE} \
    CONFIG.PSU__GEN_IPI_1__MASTER {RPU0} \
    CONFIG.PSU__GEN_IPI_2__MASTER {RPU1} \
    CONFIG.PSU__GEN_IPI_3__MASTER {PMU} \
    CONFIG.PSU__GEN_IPI_4__MASTER {PMU} \
    CONFIG.PSU__GEN_IPI_5__MASTER {PMU} \
    CONFIG.PSU__GEN_IPI_6__MASTER {PMU} \
    CONFIG.PSU__GEN_IPI_7__MASTER {NONE} \
    CONFIG.PSU__GEN_IPI_8__MASTER {NONE} \
    CONFIG.PSU__GEN_IPI_9__MASTER {NONE} \
    CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
    CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO1_MIO__IO {MIO 26 .. 51} \
    CONFIG.PSU__GPIO1_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO2_MIO__IO {MIO 52 .. 77} \
    CONFIG.PSU__GPIO2_MIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO_EMIO_WIDTH {1} \
    CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__GPIO_EMIO__WIDTH {[94:0]} \
    CONFIG.PSU__GPU_PP0__POWER__ON {1} \
    CONFIG.PSU__GPU_PP1__POWER__ON {1} \
    CONFIG.PSU__GT_REF_CLK__FREQMHZ {33.333} \
    CONFIG.PSU__HPM0_FPD__NUM_READ_THREADS {4} \
    CONFIG.PSU__HPM0_FPD__NUM_WRITE_THREADS {4} \
    CONFIG.PSU__HPM0_LPD__NUM_READ_THREADS {4} \
    CONFIG.PSU__HPM0_LPD__NUM_WRITE_THREADS {4} \
    CONFIG.PSU__HPM1_FPD__NUM_READ_THREADS {4} \
    CONFIG.PSU__HPM1_FPD__NUM_WRITE_THREADS {4} \
    CONFIG.PSU__I2C0_LOOP_I2C1__ENABLE {0} \
    CONFIG.PSU__I2C0__GRP_INT__ENABLE {0} \
    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 34 .. 35} \
    CONFIG.PSU__I2C1__GRP_INT__ENABLE {0} \
    CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 36 .. 37} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC0_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC1_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC2_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__IOU_TTC_APB_CLK__TTC3_SEL {APB} \
    CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__TTC1__ACT_FREQMHZ {100} \
    CONFIG.PSU__IOU_SLCR__TTC2__ACT_FREQMHZ {100} \
    CONFIG.PSU__IOU_SLCR__TTC3__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__IRQ_P2F_ADMA_CHAN__INT {0} \
    CONFIG.PSU__IRQ_P2F_AIB_AXI__INT {0} \
    CONFIG.PSU__IRQ_P2F_AMS__INT {0} \
    CONFIG.PSU__IRQ_P2F_APM_FPD__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_COMM__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_CPUMNT__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_CTI__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_EXTERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_IPI__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_L2ERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_PMU__INT {0} \
    CONFIG.PSU__IRQ_P2F_APU_REGS__INT {0} \
    CONFIG.PSU__IRQ_P2F_ATB_LPD__INT {0} \
    CONFIG.PSU__IRQ_P2F_CAN0__INT {0} \
    CONFIG.PSU__IRQ_P2F_CAN1__INT {0} \
    CONFIG.PSU__IRQ_P2F_CLKMON__INT {0} \
    CONFIG.PSU__IRQ_P2F_CSUPMU_WDT__INT {0} \
    CONFIG.PSU__IRQ_P2F_DDR_SS__INT {0} \
    CONFIG.PSU__IRQ_P2F_DPDMA__INT {0} \
    CONFIG.PSU__IRQ_P2F_EFUSE__INT {0} \
    CONFIG.PSU__IRQ_P2F_ENT1_WAKEUP__INT {0} \
    CONFIG.PSU__IRQ_P2F_ENT1__INT {0} \
    CONFIG.PSU__IRQ_P2F_ENT2_WAKEUP__INT {0} \
    CONFIG.PSU__IRQ_P2F_ENT2__INT {0} \
    CONFIG.PSU__IRQ_P2F_FPD_APB__INT {0} \
    CONFIG.PSU__IRQ_P2F_FPD_ATB_ERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_FP_WDT__INT {0} \
    CONFIG.PSU__IRQ_P2F_GDMA_CHAN__INT {0} \
    CONFIG.PSU__IRQ_P2F_GPIO__INT {0} \
    CONFIG.PSU__IRQ_P2F_GPU__INT {0} \
    CONFIG.PSU__IRQ_P2F_I2C0__INT {0} \
    CONFIG.PSU__IRQ_P2F_I2C1__INT {0} \
    CONFIG.PSU__IRQ_P2F_LPD_APB__INT {0} \
    CONFIG.PSU__IRQ_P2F_LPD_APM__INT {0} \
    CONFIG.PSU__IRQ_P2F_LP_WDT__INT {0} \
    CONFIG.PSU__IRQ_P2F_OCM_ERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_PCIE_DMA__INT {0} \
    CONFIG.PSU__IRQ_P2F_PCIE_LEGACY__INT {0} \
    CONFIG.PSU__IRQ_P2F_PCIE_MSC__INT {0} \
    CONFIG.PSU__IRQ_P2F_PCIE_MSI__INT {0} \
    CONFIG.PSU__IRQ_P2F_PL_IPI__INT {0} \
    CONFIG.PSU__IRQ_P2F_QSPI__INT {0} \
    CONFIG.PSU__IRQ_P2F_R5_CORE0_ECC_ERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_R5_CORE1_ECC_ERR__INT {0} \
    CONFIG.PSU__IRQ_P2F_RPU_IPI__INT {0} \
    CONFIG.PSU__IRQ_P2F_RPU_PERMON__INT {0} \
    CONFIG.PSU__IRQ_P2F_RTC_ALARM__INT {0} \
    CONFIG.PSU__IRQ_P2F_RTC_SECONDS__INT {0} \
    CONFIG.PSU__IRQ_P2F_SATA__INT {0} \
    CONFIG.PSU__IRQ_P2F_SPI0__INT {0} \
    CONFIG.PSU__IRQ_P2F_SPI1__INT {0} \
    CONFIG.PSU__IRQ_P2F_TTC0__INT0 {0} \
    CONFIG.PSU__IRQ_P2F_TTC0__INT1 {0} \
    CONFIG.PSU__IRQ_P2F_TTC0__INT2 {0} \
    CONFIG.PSU__IRQ_P2F_TTC3__INT0 {0} \
    CONFIG.PSU__IRQ_P2F_TTC3__INT1 {0} \
    CONFIG.PSU__IRQ_P2F_TTC3__INT2 {0} \
    CONFIG.PSU__IRQ_P2F_UART0__INT {0} \
    CONFIG.PSU__IRQ_P2F_UART1__INT {0} \
    CONFIG.PSU__IRQ_P2F_USB3_ENDPOINT__INT0 {0} \
    CONFIG.PSU__IRQ_P2F_USB3_ENDPOINT__INT1 {0} \
    CONFIG.PSU__IRQ_P2F_USB3_OTG__INT0 {0} \
    CONFIG.PSU__IRQ_P2F_USB3_OTG__INT1 {0} \
    CONFIG.PSU__IRQ_P2F_USB3_PMU_WAKEUP__INT {0} \
    CONFIG.PSU__IRQ_P2F_XMPU_FPD__INT {0} \
    CONFIG.PSU__IRQ_P2F_XMPU_LPD__INT {0} \
    CONFIG.PSU__IRQ_P2F__INTF_FPD_SMMU__INT {0} \
    CONFIG.PSU__IRQ_P2F__INTF_PPD_CCI__INT {0} \
    CONFIG.PSU__L2_BANK0__POWER__ON {1} \
    CONFIG.PSU__LPDMA0_COHERENCY {0} \
    CONFIG.PSU__LPDMA1_COHERENCY {0} \
    CONFIG.PSU__LPDMA2_COHERENCY {0} \
    CONFIG.PSU__LPDMA3_COHERENCY {0} \
    CONFIG.PSU__LPDMA4_COHERENCY {0} \
    CONFIG.PSU__LPDMA5_COHERENCY {0} \
    CONFIG.PSU__LPDMA6_COHERENCY {0} \
    CONFIG.PSU__LPDMA7_COHERENCY {0} \
    CONFIG.PSU__LPD_SLCR__CSUPMU_WDT_CLK_SEL__SELECT {APB} \
    CONFIG.PSU__LPD_SLCR__CSUPMU__ACT_FREQMHZ {100.000000} \
    CONFIG.PSU__MAXIGP2__DATA_WIDTH {128} \
    CONFIG.PSU__M_AXI_GP0_SUPPORTS_NARROW_BURST {1} \
    CONFIG.PSU__M_AXI_GP1_SUPPORTS_NARROW_BURST {1} \
    CONFIG.PSU__M_AXI_GP2_SUPPORTS_NARROW_BURST {1} \
    CONFIG.PSU__NAND__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__NAND__READY_BUSY__ENABLE {0} \
    CONFIG.PSU__NUM_FABRIC_RESETS {1} \
    CONFIG.PSU__OCM_BANK0__POWER__ON {1} \
    CONFIG.PSU__OCM_BANK1__POWER__ON {1} \
    CONFIG.PSU__OCM_BANK2__POWER__ON {1} \
    CONFIG.PSU__OCM_BANK3__POWER__ON {1} \
    CONFIG.PSU__OVERRIDE_HPX_QOS {0} \
    CONFIG.PSU__OVERRIDE__BASIC_CLOCK {0} \
    CONFIG.PSU__PCIE__ACS_VIOLAION {0} \
    CONFIG.PSU__PCIE__AER_CAPABILITY {0} \
    CONFIG.PSU__PCIE__CLASS_CODE_BASE {0x06} \
    CONFIG.PSU__PCIE__CLASS_CODE_INTERFACE {0x0} \
    CONFIG.PSU__PCIE__CLASS_CODE_SUB {0x04} \
    CONFIG.PSU__PCIE__DEVICE_ID {0xD021} \
    CONFIG.PSU__PCIE__INTX_GENERATION {0} \
    CONFIG.PSU__PCIE__MSIX_CAPABILITY {0} \
    CONFIG.PSU__PCIE__MSI_CAPABILITY {0} \
    CONFIG.PSU__PCIE__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__PCIE__PERIPHERAL__ENDPOINT_ENABLE {1} \
    CONFIG.PSU__PCIE__PERIPHERAL__ROOTPORT_ENABLE {0} \
    CONFIG.PSU__PCIE__RESET__POLARITY {Active Low} \
    CONFIG.PSU__PCIE__REVISION_ID {0x0} \
    CONFIG.PSU__PCIE__SUBSYSTEM_ID {0x7} \
    CONFIG.PSU__PCIE__SUBSYSTEM_VENDOR_ID {0x10EE} \
    CONFIG.PSU__PCIE__VENDOR_ID {0x10EE} \
    CONFIG.PSU__PJTAG__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__PL_CLK0_BUF {TRUE} \
    CONFIG.PSU__PL__POWER__ON {1} \
    CONFIG.PSU__PMU_COHERENCY {0} \
    CONFIG.PSU__PMU__AIBACK__ENABLE {0} \
    CONFIG.PSU__PMU__EMIO_GPI__ENABLE {0} \
    CONFIG.PSU__PMU__EMIO_GPO__ENABLE {0} \
    CONFIG.PSU__PMU__GPI0__ENABLE {1} \
    CONFIG.PSU__PMU__GPI0__IO {MIO 26} \
    CONFIG.PSU__PMU__GPI1__ENABLE {1} \
    CONFIG.PSU__PMU__GPI1__IO {MIO 27} \
    CONFIG.PSU__PMU__GPI2__ENABLE {0} \
    CONFIG.PSU__PMU__GPI3__ENABLE {0} \
    CONFIG.PSU__PMU__GPI4__ENABLE {0} \
    CONFIG.PSU__PMU__GPI5__ENABLE {0} \
    CONFIG.PSU__PMU__GPO0__ENABLE {1} \
    CONFIG.PSU__PMU__GPO0__IO {MIO 32} \
    CONFIG.PSU__PMU__GPO1__ENABLE {1} \
    CONFIG.PSU__PMU__GPO1__IO {MIO 33} \
    CONFIG.PSU__PMU__GPO2__ENABLE {0} \
    CONFIG.PSU__PMU__GPO3__ENABLE {0} \
    CONFIG.PSU__PMU__GPO4__ENABLE {0} \
    CONFIG.PSU__PMU__GPO5__ENABLE {0} \
    CONFIG.PSU__PMU__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__PMU__PLERROR__ENABLE {0} \
    CONFIG.PSU__PRESET_APPLIED {1} \
    CONFIG.PSU__PROTECTION__DDR_SEGMENTS {SA:0x0; SIZE:32;  SA:0x40000000; SIZE:16;  SA:0x60000000; SIZE:1;  SA:0x60000000; SIZE:1;  UNIT:MB; RegionTZ:NonSecure;  UNIT:MB; RegionTZ:NonSecure;  UNIT:MB;\
RegionTZ:NonSecure;  UNIT:MB; RegionTZ:NonSecure;  WrAllowed:Read/Write; subsystemId:RPU  WrAllowed:Read/Write; subsystemId:RPU  WrAllowed:Read/Write; subsystemId:RPU  WrAllowed:Read/Write; subsystemId:RPU}\
\
    CONFIG.PSU__PROTECTION__ENABLE {0} \
    CONFIG.PSU__PROTECTION__FPD_SEGMENTS {SA:0xFD1A0000; SIZE:1280; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware    |     SA:0xFD000000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write;\
subsystemId:PMU Firmware    |     SA:0xFD010000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware    |     SA:0xFD020000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write;\
subsystemId:PMU Firmware    |     SA:0xFD030000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware    |     SA:0xFD040000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write;\
subsystemId:PMU Firmware    |     SA:0xFD050000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware    |     SA:0xFD610000; SIZE:512; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write;\
subsystemId:PMU Firmware    |     SA:0xFD5D0000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware    |    SA:0xFD3D0000 ;SIZE:64;UNIT:KB ;RegionTZ:NonSecure ;WrAllowed:Read/Write;subsystemId:APU\
 |    SA:0xFD3D0000 ;SIZE:64;UNIT:KB ;RegionTZ:NonSecure ;WrAllowed:Read/Write;subsystemId:RPU} \
    CONFIG.PSU__PROTECTION__LPD_SEGMENTS {;RegionTZ:NonSecure ;WrAllowed:Read/Write;subsystemId:APU  ;RegionTZ:NonSecure ;WrAllowed:Read/Write;subsystemId:APU  ;RegionTZ:NonSecure ;WrAllowed:Read/Write;subsystemId:APU\
;SIZE:512;UNIT:KB ;RegionTZ:NonSecure  ;SIZE:64;UNIT:KB ;RegionTZ:NonSecure  ;WrAllowed:Read/Write;subsystemId:APU|SA:0xFF170000 ;SIZE:64;UNIT:KB  ;WrAllowed:Read/Write;subsystemId:APU|SA:0xFF380000 ;SIZE:512;UNIT:KB\
Firmware| SA:0xFFA70000;  Firmware| SA:0xFFA70000;  Firmware| SA:0xFFA70000;  Firmware|SA:0xFF0E0000 ;SIZE:64;UNIT:KB  RegionTZ:Secure; WrAllowed:Read/Write;  RegionTZ:Secure; WrAllowed:Read/Write;  RegionTZ:Secure;\
WrAllowed:Read/Write;  SA:0xFF000000; SIZE:64;  SA:0xFF000000; SIZE:64;  SA:0xFF020000; SIZE:64;  SA:0xFF020000; SIZE:64;  SA:0xFF060000; SIZE:64;  SA:0xFF060000; SIZE:64;  SA:0xFF0A0000; SIZE:64;  SA:0xFF0A0000;\
SIZE:64;  SA:0xFF110000; SIZE:64;  SA:0xFF110000; SIZE:64;  SA:0xFF410000; SIZE:640;  SA:0xFF980000; SIZE:64;  SA:0xFF9A0000; SIZE:64;  SA:0xFFCC0000; SIZE:64;  SIZE:2560; UNIT:KB;  SIZE:64; UNIT:KB; \
SIZE:768; UNIT:KB;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;\
UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  UNIT:KB; RegionTZ:Secure;  WrAllowed:Read/Write;\
subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU\
WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write;\
subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  WrAllowed:Read/Write; subsystemId:PMU  subsystemId:PMU Firmware|  subsystemId:PMU Firmware|  subsystemId:PMU Firmware|} \
    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;0|S_AXI_LPD:NA;1|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;0|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;0|SD0:NonSecure;0|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;0|GEM2:NonSecure;1|GEM1:NonSecure;1|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1}\
\
    CONFIG.PSU__PROTECTION__MASTERS_TZ {GEM0:NonSecure|SD1:NonSecure|GEM2:NonSecure|GEM1:NonSecure|GEM3:NonSecure|PCIe:NonSecure|DP:NonSecure|NAND:NonSecure|GPU:NonSecure|RPU1:Secure|RPU0:Secure|SATA0:NonSecure|SATA1:NonSecure|USB1:NonSecure|USB0:NonSecure|LDMA:NonSecure|FDMA:NonSecure|QSPI:NonSecure|SD0:NonSecure}\
\
    CONFIG.PSU__PROTECTION__OCM_SEGMENTS {SA:0xFFFC0000; SIZE:192;  SA:0xFFFF0000; SIZE:64;  SA:0xFFFF0000; SIZE:64;  UNIT:KB; RegionTZ:NonSecure;  UNIT:KB; RegionTZ:NonSecure;  UNIT:KB; RegionTZ:NonSecure;\
WrAllowed:Read/Write; subsystemId:RPU  WrAllowed:Read/Write; subsystemId:RPU  WrAllowed:Read/Write; subsystemId:RPU} \
    CONFIG.PSU__PROTECTION__PRESUBSYSTEMS {NONE} \
    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;0|LPD;USB3_0;FF9D0000;FF9DFFFF;0|LPD;UART1;FF010000;FF01FFFF;1|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;0|LPD;TTC1;FF120000;FF12FFFF;0|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;1|LPD;SPI0;FF040000;FF04FFFF;1|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;0|LPD;SD0;FF160000;FF16FFFF;0|FPD;SATA;FD0C0000;FD0CFFFF;1|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;0|LPD;GEM2;FF0D0000;FF0DFFFF;1|LPD;GEM1;FF0C0000;FF0CFFFF;1|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display\
Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;800000000;0|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;1|LPD;CAN0;FF060000;FF06FFFF;1|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1}\
\
    CONFIG.PSU__PROTECTION__SUBSYSTEMS {APU:APU|RPU:RPU0|PMU Firmware:PMU} \
    CONFIG.PSU__PSS_ALT_REF_CLK__ENABLE {0} \
    CONFIG.PSU__PSS_ALT_REF_CLK__FREQMHZ {33.333} \
    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
    CONFIG.PSU__QSPI_COHERENCY {0} \
    CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
    CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
    CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
    CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
    CONFIG.PSU__REPORT__DBGLOG {0} \
    CONFIG.PSU__RPU_COHERENCY {0} \
    CONFIG.PSU__RPU__POWER__ON {1} \
    CONFIG.PSU__SATA__LANE0__ENABLE {1} \
    CONFIG.PSU__SATA__LANE0__IO {GT Lane2} \
    CONFIG.PSU__SATA__LANE1__ENABLE {0} \
    CONFIG.PSU__SATA__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SATA__REF_CLK_FREQ {125} \
    CONFIG.PSU__SATA__REF_CLK_SEL {Ref Clk1} \
    CONFIG.PSU__SAXIGP6__DATA_WIDTH {32} \
    CONFIG.PSU__SD0__CLK_100_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD0__CLK_200_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD0__CLK_50_DDR_ITAP_DLY {0x3D} \
    CONFIG.PSU__SD0__CLK_50_DDR_OTAP_DLY {0x4} \
    CONFIG.PSU__SD0__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD0__CLK_50_SDR_OTAP_DLY {0x5} \
    CONFIG.PSU__SD0__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__SD0__RESET__ENABLE {1} \
    CONFIG.PSU__SD1__CLK_100_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD1__CLK_200_SDR_OTAP_DLY {0x3} \
    CONFIG.PSU__SD1__CLK_50_DDR_ITAP_DLY {0x3D} \
    CONFIG.PSU__SD1__CLK_50_DDR_OTAP_DLY {0x4} \
    CONFIG.PSU__SD1__CLK_50_SDR_ITAP_DLY {0x15} \
    CONFIG.PSU__SD1__CLK_50_SDR_OTAP_DLY {0x5} \
    CONFIG.PSU__SD1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__SD1__RESET__ENABLE {0} \
    CONFIG.PSU__SPI0_LOOP_SPI1__ENABLE {0} \
    CONFIG.PSU__SPI0__GRP_SS0__IO {MIO 67} \
    CONFIG.PSU__SPI0__GRP_SS1__ENABLE {1} \
    CONFIG.PSU__SPI0__GRP_SS1__IO {MIO 66} \
    CONFIG.PSU__SPI0__GRP_SS2__ENABLE {1} \
    CONFIG.PSU__SPI0__GRP_SS2__IO {MIO 65} \
    CONFIG.PSU__SPI0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SPI0__PERIPHERAL__IO {MIO 64 .. 69} \
    CONFIG.PSU__SPI1__GRP_SS0__IO {MIO 73} \
    CONFIG.PSU__SPI1__GRP_SS1__ENABLE {1} \
    CONFIG.PSU__SPI1__GRP_SS1__IO {MIO 72} \
    CONFIG.PSU__SPI1__GRP_SS2__ENABLE {1} \
    CONFIG.PSU__SPI1__GRP_SS2__IO {MIO 71} \
    CONFIG.PSU__SPI1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SPI1__PERIPHERAL__IO {MIO 70 .. 75} \
    CONFIG.PSU__SWDT0__CLOCK__ENABLE {0} \
    CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SWDT0__PERIPHERAL__IO {NA} \
    CONFIG.PSU__SWDT0__RESET__ENABLE {0} \
    CONFIG.PSU__SWDT1__CLOCK__ENABLE {0} \
    CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SWDT1__PERIPHERAL__IO {NA} \
    CONFIG.PSU__SWDT1__RESET__ENABLE {0} \
    CONFIG.PSU__TCM0A__POWER__ON {1} \
    CONFIG.PSU__TCM0B__POWER__ON {1} \
    CONFIG.PSU__TCM1A__POWER__ON {1} \
    CONFIG.PSU__TCM1B__POWER__ON {1} \
    CONFIG.PSU__TESTSCAN__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TRACE__INTERNAL_WIDTH {32} \
    CONFIG.PSU__TRACE__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TRISTATE__INVERTED {1} \
    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
    CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC0__PERIPHERAL__IO {NA} \
    CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC1__PERIPHERAL__IO {NA} \
    CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC2__PERIPHERAL__IO {NA} \
    CONFIG.PSU__TTC3__CLOCK__ENABLE {0} \
    CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC3__PERIPHERAL__IO {NA} \
    CONFIG.PSU__TTC3__WAVEOUT__ENABLE {0} \
    CONFIG.PSU__UART0_LOOP_UART1__ENABLE {0} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__UART0__MODEM__ENABLE {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 18 .. 19} \
    CONFIG.PSU__UART1__BAUD_RATE {115200} \
    CONFIG.PSU__UART1__MODEM__ENABLE {0} \
    CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART1__PERIPHERAL__IO {MIO 28 .. 29} \
    CONFIG.PSU__USB0__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__USB0__RESET__ENABLE {0} \
    CONFIG.PSU__USB1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__USB1__RESET__ENABLE {0} \
    CONFIG.PSU__USE_DIFF_RW_CLK_GP6 {0} \
    CONFIG.PSU__USE__ADMA {0} \
    CONFIG.PSU__USE__APU_LEGACY_INTERRUPT {0} \
    CONFIG.PSU__USE__AUDIO {0} \
    CONFIG.PSU__USE__CLK {0} \
    CONFIG.PSU__USE__CLK0 {0} \
    CONFIG.PSU__USE__CLK1 {0} \
    CONFIG.PSU__USE__CLK2 {0} \
    CONFIG.PSU__USE__CLK3 {0} \
    CONFIG.PSU__USE__CROSS_TRIGGER {0} \
    CONFIG.PSU__USE__DDR_INTF_REQUESTED {0} \
    CONFIG.PSU__USE__DEBUG__TEST {0} \
    CONFIG.PSU__USE__EVENT_RPU {0} \
    CONFIG.PSU__USE__FABRIC__RST {1} \
    CONFIG.PSU__USE__FTM {0} \
    CONFIG.PSU__USE__GDMA {0} \
    CONFIG.PSU__USE__IRQ {0} \
    CONFIG.PSU__USE__IRQ0 {1} \
    CONFIG.PSU__USE__IRQ1 {0} \
    CONFIG.PSU__USE__M_AXI_GP0 {0} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {1} \
    CONFIG.PSU__USE__PROC_EVENT_BUS {0} \
    CONFIG.PSU__USE__RPU_LEGACY_INTERRUPT {0} \
    CONFIG.PSU__USE__RST0 {0} \
    CONFIG.PSU__USE__RST1 {0} \
    CONFIG.PSU__USE__RST2 {0} \
    CONFIG.PSU__USE__RST3 {0} \
    CONFIG.PSU__USE__RTC {0} \
    CONFIG.PSU__USE__STM {0} \
    CONFIG.PSU__USE__S_AXI_ACE {0} \
    CONFIG.PSU__USE__S_AXI_ACP {0} \
    CONFIG.PSU__USE__S_AXI_GP0 {0} \
    CONFIG.PSU__USE__S_AXI_GP1 {0} \
    CONFIG.PSU__USE__S_AXI_GP2 {0} \
    CONFIG.PSU__USE__S_AXI_GP3 {0} \
    CONFIG.PSU__USE__S_AXI_GP4 {0} \
    CONFIG.PSU__USE__S_AXI_GP5 {0} \
    CONFIG.PSU__USE__S_AXI_GP6 {1} \
    CONFIG.PSU__USE__USB3_0_HUB {0} \
    CONFIG.PSU__USE__USB3_1_HUB {0} \
    CONFIG.PSU__USE__VIDEO {0} \
    CONFIG.PSU__VIDEO_REF_CLK__ENABLE {0} \
    CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ {33.333} \
    CONFIG.QSPI_BOARD_INTERFACE {custom} \
    CONFIG.SATA_BOARD_INTERFACE {custom} \
    CONFIG.SD0_BOARD_INTERFACE {custom} \
    CONFIG.SD1_BOARD_INTERFACE {custom} \
    CONFIG.SPI0_BOARD_INTERFACE {custom} \
    CONFIG.SPI1_BOARD_INTERFACE {custom} \
    CONFIG.SUBPRESET1 {Custom} \
    CONFIG.SUBPRESET2 {Custom} \
    CONFIG.SWDT0_BOARD_INTERFACE {custom} \
    CONFIG.SWDT1_BOARD_INTERFACE {custom} \
    CONFIG.TRACE_BOARD_INTERFACE {custom} \
    CONFIG.TTC0_BOARD_INTERFACE {custom} \
    CONFIG.TTC1_BOARD_INTERFACE {custom} \
    CONFIG.TTC2_BOARD_INTERFACE {custom} \
    CONFIG.TTC3_BOARD_INTERFACE {custom} \
    CONFIG.UART0_BOARD_INTERFACE {custom} \
    CONFIG.UART1_BOARD_INTERFACE {custom} \
    CONFIG.USB0_BOARD_INTERFACE {custom} \
    CONFIG.USB1_BOARD_INTERFACE {custom} \
  ] $zynq_ultra_ps_e_0

  # ---- Conexiones AXI ----
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_LPD [get_bd_intf_pins mz_system/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_LPD]
  connect_bd_intf_net -intf_net mz_analog_adapter_M_AXI_LPD [get_bd_intf_pins mz_analog_adapter/M_AXI_LPD] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_LPD]
  connect_bd_intf_net -intf_net mz_system_M_AXI_A1_ADC  [get_bd_intf_pins mz_system/M_AXI_A1_ADC]  [get_bd_intf_pins mz_analog_adapter/S_AXI_A1_ADC]
  connect_bd_intf_net -intf_net mz_system_M_AXI_A2_ADC  [get_bd_intf_pins mz_system/M_AXI_A2_ADC]  [get_bd_intf_pins mz_analog_adapter/S_AXI_A2_ADC]
  connect_bd_intf_net -intf_net mz_system_M_AXI_A3_ADC  [get_bd_intf_pins mz_system/M_AXI_A3_ADC]  [get_bd_intf_pins mz_analog_adapter/S_AXI_A3_ADC]
  connect_bd_intf_net -intf_net mz_system_M_AXI_A1_GPIO [get_bd_intf_pins mz_system/M_AXI_A1_GPIO] [get_bd_intf_pins mz_analog_adapter/S_AXI_A1_GPIO]
  connect_bd_intf_net -intf_net mz_system_M_AXI_PWM_0   [get_bd_intf_pins mz_system/M_AXI_PWM_0]   [get_bd_intf_pins AXI_PWM_0/s00_axi]
  connect_bd_intf_net -intf_net mz_system_M_AXI_PHASE_DETECTOR [get_bd_intf_pins mz_system/M_AXI_PHASE_DETECTOR] [get_bd_intf_pins AXI_PHASE_DETECTOR_v_0/s00_axi]
  connect_bd_intf_net -intf_net mz_system_M_AXI_CLOCK_FLAG_DIV [get_bd_intf_pins mz_system/M_AXI_CLOCK_FLAG_DIV] [get_bd_intf_pins mz_analog_adapter/S_AXI_CLOCK_FLAG_DIV]

  # ---- Reloj unico (pl_clk0, 100 MHz) y reset ----
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
      [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/saxi_lpd_aclk] \
      [get_bd_pins mz_system/clk] [get_bd_pins mz_analog_adapter/s00_axi_aclk] \
      [get_bd_pins AXI_PWM_0/s00_axi_aclk] [get_bd_pins AXI_PWM_0/pwm_clk] \
      [get_bd_pins AXI_PHASE_DETECTOR_v_0/s00_axi_aclk] [get_bd_pins AXI_PHASE_DETECTOR_v_0/S_COUNTER_CLK]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins mz_system/resetn]
  connect_bd_net -net mz_system_peripheral_aresetn [get_bd_pins mz_system/peripheral_aresetn] \
      [get_bd_pins mz_analog_adapter/s00_axi_aresetn] \
      [get_bd_pins AXI_PWM_0/s00_axi_aresetn] \
      [get_bd_pins AXI_PHASE_DETECTOR_v_0/s00_axi_aresetn]

  # ---- Interrupcion unica: mz_system/irq (interrupt_clock) -> pl_ps_irq0[0] (XPS_FPGA0_INT_ID)
  #      La misma senal es la base de tiempo del trigger de ADC y del averager.
  #      mz_analog_adapter/clock_flag_div_axi_mz_0 divide el mismo reloj base que genera irq (clk_base):
  #      f_ADC = f_base / MAX y f_ISR = f_base / N -> N/MAX muestras por periodo, exactas.
  #      El trigger del LTC2311 es clk_output (onda cuadrada, no el flag de 1 ciclo) para que
  #      nunca se pierda al muestrearlo con los 100 MHz del ADC.
  connect_bd_net -net mz_system_clk_base [get_bd_pins mz_system/clk_base] [get_bd_pins mz_analog_adapter/clk_base]
  connect_bd_net -net mz_system_irq [get_bd_pins mz_system/irq] \
      [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0] \
      [get_bd_pins mz_analog_adapter/clock_base_2sync]

  # ---- Habilitacion del DataMover y del MAX11331 (bit 4 de mz_enable) ----
  connect_bd_net -net mz_system_ENABLE_AXI2TCM [get_bd_pins mz_system/ENABLE_AXI2TCM] [get_bd_pins mz_analog_adapter/ENABLE_AXI2TCM]

  # ---- Puertos analogicos ----
  connect_bd_net -net A1_IN_1 [get_bd_ports A1_IN] [get_bd_pins mz_analog_adapter/A1_IN]
  connect_bd_net -net A2_IN_1 [get_bd_ports A2_IN] [get_bd_pins mz_analog_adapter/A2_IN]
  connect_bd_net -net A3_IN_1 [get_bd_ports A3_IN] [get_bd_pins mz_analog_adapter/A3_IN]
  connect_bd_net -net mz_analog_adapter_A1_OUT_CLK [get_bd_ports A1_OUT_CLK] [get_bd_pins mz_analog_adapter/A1_OUT_CLK]
  connect_bd_net -net mz_analog_adapter_A2_OUT_CLK [get_bd_ports A2_OUT_CLK] [get_bd_pins mz_analog_adapter/A2_OUT_CLK]
  connect_bd_net -net mz_analog_adapter_A1_OUT_CNV [get_bd_ports A1_OUT_CNV_0] [get_bd_ports A1_OUT_CNV_1] [get_bd_pins mz_analog_adapter/A1_OUT_CNV]
  connect_bd_net -net mz_analog_adapter_A2_OUT_CNV [get_bd_ports A2_OUT_CNV_0] [get_bd_ports A2_OUT_CNV_1] [get_bd_pins mz_analog_adapter/A2_OUT_CNV]
  connect_bd_net -net mz_analog_adapter_A3_OUT_CS   [get_bd_ports A3_OUT_CS]   [get_bd_pins mz_analog_adapter/A3_OUT_CS]
  connect_bd_net -net mz_analog_adapter_A3_OUT_MOSI [get_bd_ports A3_OUT_MOSI] [get_bd_pins mz_analog_adapter/A3_OUT_MOSI]
  connect_bd_net -net mz_analog_adapter_A3_OUT_SCLK [get_bd_ports A3_OUT_SCLK] [get_bd_pins mz_analog_adapter/A3_OUT_SCLK]

  # ---- Compuertas AXI_PWM_0 -> D1 ----
  connect_bd_net -net AXI_PWM_0_G1 [get_bd_pins AXI_PWM_0/G1] [get_bd_pins mz_digital_adapter/G1]
  connect_bd_net -net AXI_PWM_0_G2 [get_bd_pins AXI_PWM_0/G2] [get_bd_pins mz_digital_adapter/G2]
  connect_bd_net -net AXI_PWM_0_G3 [get_bd_pins AXI_PWM_0/G3] [get_bd_pins mz_digital_adapter/G3]
  connect_bd_net -net AXI_PWM_0_G4 [get_bd_pins AXI_PWM_0/G4] [get_bd_pins mz_digital_adapter/G4]
  connect_bd_net -net AXI_PWM_0_enable [get_bd_pins AXI_PWM_0/enable] [get_bd_pins mz_digital_adapter/enable]
  connect_bd_net -net AXI_PWM_0_square [get_bd_pins AXI_PWM_0/square] [get_bd_pins mz_digital_adapter/square] [get_bd_pins AXI_PHASE_DETECTOR_v_0/S_SIG_B]
  connect_bd_net -net mz_digital_adapter_D1_OUT [get_bd_ports D1_OUT] [get_bd_pins mz_digital_adapter/D1_OUT]

  # ---- Detector de fase ----
  connect_bd_net -net D2_IN_PHASE_1 [get_bd_ports D2_IN_PHASE] [get_bd_pins AXI_PHASE_DETECTOR_v_0/S_SIG_A]

  # ---- Patron de habilitacion del Safety CPLD: bits 26/27 = 0, bits 28/29 = ENABLE_CPLD_HIGH ----
  connect_bd_net -net mz_system_ENABLE_CPLD_LOW [get_bd_pins mz_system/ENABLE_CPLD_LOW] \
      [get_bd_ports D1_OUT_26] [get_bd_ports D1_OUT_27] [get_bd_ports D2_OUT_26] [get_bd_ports D2_OUT_27] \
      [get_bd_ports D3_OUT_26] [get_bd_ports D3_OUT_27] [get_bd_ports D4_OUT_26] [get_bd_ports D4_OUT_27]
  connect_bd_net -net mz_system_ENABLE_CPLD_HIGH [get_bd_pins mz_system/ENABLE_CPLD_HIGH] \
      [get_bd_ports D1_OUT_28] [get_bd_ports D1_OUT_29] [get_bd_ports D2_OUT_28] [get_bd_ports D2_OUT_29] \
      [get_bd_ports D3_OUT_28] [get_bd_ports D3_OUT_29] [get_bd_ports D4_OUT_28] [get_bd_ports D4_OUT_29]

  # ---- Mapa de direcciones (mismas direcciones que el proyecto original) ----
  set ps_data [get_bd_addr_spaces zynq_ultra_ps_e_0/Data]
  assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_analog_adapter/A1_adapter/A1_ADC_LTC2311/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x80010000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_analog_adapter/A2_adapter/A2_ADC_LTC2311/S00_AXI/S00_AXI_reg] -force
  assign_bd_address -offset 0x80020000 -range 0x00001000 -target_address_space $ps_data [get_bd_addr_segs mz_analog_adapter/A3_adapter/ADC_MAX11331_top_0/s_axi_lite/reg0] -force
  assign_bd_address -offset 0x80021000 -range 0x00001000 -target_address_space $ps_data [get_bd_addr_segs AXI_PHASE_DETECTOR_v_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x80022000 -range 0x00001000 -target_address_space $ps_data [get_bd_addr_segs AXI_PWM_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x80023000 -range 0x00001000 -target_address_space $ps_data [get_bd_addr_segs mz_system/interrupt_clock/clock_div_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x80130000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_system/interrupt_clock/clk_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x800E0000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_system/timer_uptime_64bit/S_AXI/Reg] -force
  assign_bd_address -offset 0x800F0000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_system/mz_enable/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x80100000 -range 0x00010000 -target_address_space $ps_data [get_bd_addr_segs mz_analog_adapter/A1_adapter/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80110000 -range 0x00001000 -target_address_space $ps_data [get_bd_addr_segs mz_analog_adapter/clock_flag_div_axi_mz_0/s00_axi/reg0] -force

  set dm_space [get_bd_addr_spaces mz_analog_adapter/DataMover/AXI2TCM_0/M00_AXI]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space $dm_space [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP6/LPD_DDR_LOW] -force
  assign_bd_address -offset 0xFF000000 -range 0x01000000 -target_address_space $dm_space [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP6/LPD_LPS_OCM] -force
  assign_bd_address -offset 0xC0000000 -range 0x20000000 -target_address_space $dm_space [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP6/LPD_QSPI] -force

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
