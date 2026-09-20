# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "COMP_REG_DEFAULT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CONTROL_REG_DEFAULT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAX_VALUE_REG_DEFAULT" -parent ${Page_0}


}

proc update_PARAM_VALUE.COMP_REG_DEFAULT { PARAM_VALUE.COMP_REG_DEFAULT } {
	# Procedure called to update COMP_REG_DEFAULT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COMP_REG_DEFAULT { PARAM_VALUE.COMP_REG_DEFAULT } {
	# Procedure called to validate COMP_REG_DEFAULT
	return true
}

proc update_PARAM_VALUE.CONTROL_REG_DEFAULT { PARAM_VALUE.CONTROL_REG_DEFAULT } {
	# Procedure called to update CONTROL_REG_DEFAULT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONTROL_REG_DEFAULT { PARAM_VALUE.CONTROL_REG_DEFAULT } {
	# Procedure called to validate CONTROL_REG_DEFAULT
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.MAX_VALUE_REG_DEFAULT { PARAM_VALUE.MAX_VALUE_REG_DEFAULT } {
	# Procedure called to update MAX_VALUE_REG_DEFAULT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAX_VALUE_REG_DEFAULT { PARAM_VALUE.MAX_VALUE_REG_DEFAULT } {
	# Procedure called to validate MAX_VALUE_REG_DEFAULT
	return true
}


proc update_MODELPARAM_VALUE.CONTROL_REG_DEFAULT { MODELPARAM_VALUE.CONTROL_REG_DEFAULT PARAM_VALUE.CONTROL_REG_DEFAULT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONTROL_REG_DEFAULT}] ${MODELPARAM_VALUE.CONTROL_REG_DEFAULT}
}

proc update_MODELPARAM_VALUE.MAX_VALUE_REG_DEFAULT { MODELPARAM_VALUE.MAX_VALUE_REG_DEFAULT PARAM_VALUE.MAX_VALUE_REG_DEFAULT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAX_VALUE_REG_DEFAULT}] ${MODELPARAM_VALUE.MAX_VALUE_REG_DEFAULT}
}

proc update_MODELPARAM_VALUE.COMP_REG_DEFAULT { MODELPARAM_VALUE.COMP_REG_DEFAULT PARAM_VALUE.COMP_REG_DEFAULT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COMP_REG_DEFAULT}] ${MODELPARAM_VALUE.COMP_REG_DEFAULT}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

