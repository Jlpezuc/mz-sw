#*****************************************************************************************
# build.tcl - MicroZohm (vivado)
#
# Regenera desde cero el proyecto Vivado 'microzohm' (project/microzohm.xpr) con el
# block design minimo 'mzsys' (bd/mzsys.tcl) y el wrapper VHDL mzsys_wrapper.
#
# Uso (consola Tcl de Vivado 2022.2):
#     cd <mz-sw>/vivado
#     source build.tcl
#
# O en batch:
#     vivado -mode batch -source build.tcl [-tclargs --board_part <board>]
#
# Estructura de carpetas:
#     bd/            mzsys.tcl  -> block design
#     board_files/   board files Trenz TE0808
#     constraints/   te0808_mz/*.xdc (solo puertos usados)
#     project/       proyecto generado (no versionar, ver project/.gitignore)
#
# Todos los IP cores (propios y del framework) se toman de <mz-sw>/ip_cores.
#*****************************************************************************************

# Directorio de referencia para rutas relativas (por defecto, el del script)
set origin_dir [file normalize [file dirname [info script]]]
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Board part por defecto (SoM Trenz TE0808 9EG)
set board_part "trenz.biz:te0808_9eg_1e:part0:3.0"
set part       "xczu9eg-ffvc900-1-e"

# Nombre del proyecto (se mantiene 'microzohm' para que tcl_scripts/* y el xsa
# 'mzsys_wrapper.xsa' sigan siendo compatibles con el proyecto original)
set _xil_proj_name_ "microzohm"
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--board_part"   { incr i; set board_part [lindex $::argv $i] }
      "--part"         { incr i; set part [lindex $::argv $i] }
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option'. Valid: --board_part --part --origin_dir --project_name"
          return 1
        }
      }
    }
  }
}

# Familia de constraints segun el SoM
if {[string first "te0808" $board_part] != -1} {
  set board_family "te0808_mz"
} else {
  set board_family "te0803_mz"
}

#-----------------------------------------------------------------------------------------
# Comprobacion de ficheros necesarios
#-----------------------------------------------------------------------------------------
set required_files [list \
  "$origin_dir/bd/mzsys.tcl" \
  "$origin_dir/constraints/$board_family/Analog_A1_packed.xdc" \
  "$origin_dir/constraints/$board_family/Analog_A2_packed.xdc" \
  "$origin_dir/constraints/$board_family/Analog_A3_packed.xdc" \
  "$origin_dir/constraints/$board_family/Digital_D1_packed.xdc" \
  "$origin_dir/constraints/$board_family/Digital_D2_packed.xdc" \
  "$origin_dir/constraints/$board_family/Digital_D3_packed.xdc" \
  "$origin_dir/constraints/$board_family/Digital_D4_packed.xdc" \
  "$origin_dir/constraints/$board_family/_i_bitgen.xdc" \
  "$origin_dir/../ip_cores/MZ_AXI_PWM_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_AXI_PHASE_DETECTOR_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_CLOCK_FLAG_DIV_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_AVERAGER_8CH_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_ADC_MAX11331_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_ADC_LTC2311_3.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_AXI2TCM_1.1/component.xml"   "$origin_dir/../ip_cores/MZ_CLOCK_DIV_1.0/component.xml" \
  "$origin_dir/../ip_cores/MZ_IOBUFDS_1.0/component.xml" \
]
set missing 0
foreach f $required_files {
  if { ![file isfile [file normalize $f]] } {
    puts "ERROR: falta el fichero [file normalize $f]"
    set missing 1
  }
}
if { $missing } {
  puts "ERROR: no se puede crear el proyecto. Si faltan component.xml en ip_cores, ejecuta ip_cores/package_all_ips.tcl"
  return 1
}

#-----------------------------------------------------------------------------------------
# Proyecto
#-----------------------------------------------------------------------------------------
cd $origin_dir
create_project ${_xil_proj_name_} ./project -part $part -force
set proj_dir [get_property directory [current_project]]

set obj [current_project]
set_property -name "board_part_repo_paths" -value "[file normalize "$origin_dir/board_files"]" -objects $obj
set_property -name "board_part" -value $board_part -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "VHDL" -objects $obj
set_property -name "target_language" -value "VHDL" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj

#-----------------------------------------------------------------------------------------
# Fuentes e IP repos
#-----------------------------------------------------------------------------------------
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set obj [get_filesets sources_1]

# Repositorio de IP cores del MicroZohm (microzohm:user:*), ver ip_cores/README.md
set_property "ip_repo_paths" [list [file normalize "$origin_dir/../ip_cores"]] $obj
update_ip_catalog -rebuild

# Modulo referenciado directamente desde el block design (buffers LVDS de A1/A2)

#-----------------------------------------------------------------------------------------
# Constraints
#-----------------------------------------------------------------------------------------
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set obj [get_filesets constrs_1]
foreach xdc {Analog_A1_packed Analog_A2_packed Analog_A3_packed \
             Digital_D1_packed Digital_D2_packed Digital_D3_packed Digital_D4_packed \
             _i_bitgen} {
  set file [file normalize "$origin_dir/constraints/$board_family/$xdc.xdc"]
  add_files -norecurse -fileset $obj [list $file]
  set_property -name "file_type" -value "XDC" -objects [get_files -of_objects $obj [list "*$file"]]
}
set_property -name "target_constrs_file" -value [file normalize "$origin_dir/constraints/$board_family/_i_bitgen.xdc"] -objects $obj

#-----------------------------------------------------------------------------------------
# Block design
#-----------------------------------------------------------------------------------------
set bd_path {./project/mzsys/mzsys.bd}
set bd_path_backup {./project/mzsys/mzsys_backup.bd}
set bd_exists [file isfile $bd_path]
if {$bd_exists == 1} {
  puts "MZ: Ya existe un block design en $bd_path, se renombra a $bd_path_backup"
  file rename -force $bd_path $bd_path_backup
}

source $origin_dir/bd/mzsys.tcl
regenerate_bd_layout

# Wrapper VHDL del block design y top del proyecto
set bd_file [get_files mzsys.bd]
set wrapper [make_wrapper -files $bd_file -top]
add_files -norecurse -fileset sources_1 $wrapper
set_property -name "top" -value "mzsys_wrapper" -objects [get_filesets sources_1]
set_property -name "top_auto_set" -value "0" -objects [get_filesets sources_1]
update_compile_order -fileset sources_1

if {$bd_exists == 1} {
  puts "\nMZ: El block design anterior quedo guardado en $bd_path_backup\n"
}
puts "\nMZ: Proyecto '${_xil_proj_name_}' creado en $proj_dir (board: $board_part)\n"
