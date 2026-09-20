# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CHANNELS_PER_MASTER" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SPI_MASTER" -parent ${Page_0}


}

proc update_PARAM_VALUE.CHANNELS_PER_MASTER { PARAM_VALUE.CHANNELS_PER_MASTER } {
	# Procedure called to update CHANNELS_PER_MASTER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CHANNELS_PER_MASTER { PARAM_VALUE.CHANNELS_PER_MASTER } {
	# Procedure called to validate CHANNELS_PER_MASTER
	return true
}

proc update_PARAM_VALUE.SPI_MASTER { PARAM_VALUE.SPI_MASTER } {
	# Procedure called to update SPI_MASTER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SPI_MASTER { PARAM_VALUE.SPI_MASTER } {
	# Procedure called to validate SPI_MASTER
	return true
}


proc update_MODELPARAM_VALUE.CHANNELS_PER_MASTER { MODELPARAM_VALUE.CHANNELS_PER_MASTER PARAM_VALUE.CHANNELS_PER_MASTER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CHANNELS_PER_MASTER}] ${MODELPARAM_VALUE.CHANNELS_PER_MASTER}
}

proc update_MODELPARAM_VALUE.SPI_MASTER { MODELPARAM_VALUE.SPI_MASTER PARAM_VALUE.SPI_MASTER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SPI_MASTER}] ${MODELPARAM_VALUE.SPI_MASTER}
}

