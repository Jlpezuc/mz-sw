open_project vivado/project/microzohm.xpr
set work_directory [get_property DIRECTORY [current_project]] ; 
cd $work_directory ; 
write_hw_platform -fixed -force -include_bit -file {../../vitis/vivado_exported_xsa/mzsys_wrapper.xsa}
