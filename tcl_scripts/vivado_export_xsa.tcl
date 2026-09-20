# Exporta la plataforma hardware (bitstream incluido) del proyecto microzohm al sitio donde
# la espera el workspace de Vitis (vitis/vivado_exported_xsa/mzsys_wrapper.xsa).
#
# Uso (con el proyecto abierto en Vivado y el bitstream generado):
#   cd [get_property DIRECTORY [current_project]]
#   source {../../tcl_scripts/vivado_export_xsa.tcl}
#
# ATENCION: el script vitis_generate_MicroZohm_workspace.tcl coge el primer *.xsa que
# encuentra en esa carpeta; borra el mzsys_wrapper.xsa antiguo para no mezclarlos.
set work_directory [get_property DIRECTORY [current_project]]
cd $work_directory
write_hw_platform -fixed -force -include_bit -file {../../vitis/vivado_exported_xsa/mzsys_wrapper.xsa}
puts "MZ: exportado ../../vitis/vivado_exported_xsa/mzsys_wrapper.xsa"
