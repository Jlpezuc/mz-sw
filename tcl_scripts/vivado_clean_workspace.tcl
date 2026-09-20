# get the absolute path to the vivado_clean_workspace.tcl script
# This script deletes all temporary files of vivado which are not source controlled by git!
# Run in Vivado Tcl console:
# source {vivado_clean_workspace.tcl}
# Run from CLI
# vivado -mode batch -source vivado_clean_workspace.tcl
set script_path [ file dirname [ file normalize [ info script ] ] ]
cd $script_path
cd ..
set FOLDER_PATH [pwd]
puts $FOLDER_PATH 
# Path to mz-sw repo on local disc
set path_vivado [file join $FOLDER_PATH vivado]
set path_project [file join $path_vivado project]
set path_mzsys [file join $path_project mzsys]

# Delete everything in /vivado/project but microzohm.xpr and .gitignore
cd $path_project
puts [pwd]
file delete -force microzohm.cache
file delete -force microzohm.hw
file delete -force microzohm.runs
file delete -force microzohm.sim
file delete -force microzohm.srcs
file delete -force microzohm.gen
file delete -force microzohm.ip_user_files
file delete -force .Xil

cd $path_mzsys
puts [pwd]
file delete -force hw_handoff
file delete -force ip
file delete -force ipshared
file delete -force sim
file delete -force synth
file delete -force {*}[glob *.bxml]
file delete -force {*}[glob *.xdc]


#set script_path [ file dirname [ file normalize [ info script ] ] ]
#cd $script_path
#exec git status
#exec git reset --hard
#exec git clean -fd
