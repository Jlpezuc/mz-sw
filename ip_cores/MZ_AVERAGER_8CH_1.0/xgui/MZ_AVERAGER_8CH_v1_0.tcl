# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "MAX_AVG_LOG2" -parent ${Page_0}
  ipgui::add_param $IPINST -name "largo_dato" -parent ${Page_0}
  ipgui::add_param $IPINST -name "sincronizar_clock_base" -parent ${Page_0}
  ipgui::add_param $IPINST -name "valores_con_signo" -parent ${Page_0}


}

proc update_PARAM_VALUE.MAX_AVG_LOG2 { PARAM_VALUE.MAX_AVG_LOG2 } {
	# Procedure called to update MAX_AVG_LOG2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAX_AVG_LOG2 { PARAM_VALUE.MAX_AVG_LOG2 } {
	# Procedure called to validate MAX_AVG_LOG2
	return true
}

proc update_PARAM_VALUE.largo_dato { PARAM_VALUE.largo_dato } {
	# Procedure called to update largo_dato when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.largo_dato { PARAM_VALUE.largo_dato } {
	# Procedure called to validate largo_dato
	return true
}

proc update_PARAM_VALUE.sincronizar_clock_base { PARAM_VALUE.sincronizar_clock_base } {
	# Procedure called to update sincronizar_clock_base when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.sincronizar_clock_base { PARAM_VALUE.sincronizar_clock_base } {
	# Procedure called to validate sincronizar_clock_base
	return true
}

proc update_PARAM_VALUE.valores_con_signo { PARAM_VALUE.valores_con_signo } {
	# Procedure called to update valores_con_signo when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.valores_con_signo { PARAM_VALUE.valores_con_signo } {
	# Procedure called to validate valores_con_signo
	return true
}


proc update_MODELPARAM_VALUE.largo_dato { MODELPARAM_VALUE.largo_dato PARAM_VALUE.largo_dato } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.largo_dato}] ${MODELPARAM_VALUE.largo_dato}
}

proc update_MODELPARAM_VALUE.MAX_AVG_LOG2 { MODELPARAM_VALUE.MAX_AVG_LOG2 PARAM_VALUE.MAX_AVG_LOG2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAX_AVG_LOG2}] ${MODELPARAM_VALUE.MAX_AVG_LOG2}
}

proc update_MODELPARAM_VALUE.valores_con_signo { MODELPARAM_VALUE.valores_con_signo PARAM_VALUE.valores_con_signo } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.valores_con_signo}] ${MODELPARAM_VALUE.valores_con_signo}
}

proc update_MODELPARAM_VALUE.sincronizar_clock_base { MODELPARAM_VALUE.sincronizar_clock_base PARAM_VALUE.sincronizar_clock_base } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.sincronizar_clock_base}] ${MODELPARAM_VALUE.sincronizar_clock_base}
}

