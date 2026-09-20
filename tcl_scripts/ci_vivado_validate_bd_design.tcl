open_project vivado/project/microzohm.xpr

open_bd_design vivado/project/mzsys/mzsys.bd
set return_msg [validate_bd_design]
set error_flag 0
 
if {$return_msg != ""} {
  set error_flag 1
}
 
puts $return_msg
exit $error_flag
