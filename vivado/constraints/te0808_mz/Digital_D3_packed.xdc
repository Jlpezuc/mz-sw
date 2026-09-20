# MicroZohm minimal (vivado2) - recorte de las constraints originales de mz-sw/vivado/constraints/te0808_mz
# Solo se conservan los puertos que existen en el block design minimo.
# D3: solo patron de habilitacion del Safety CPLD (26..29)
set_property PACKAGE_PIN P11 [get_ports {D3_OUT_26[0]}]
set_property PACKAGE_PIN P10 [get_ports {D3_OUT_27[0]}]
set_property PACKAGE_PIN W7 [get_ports {D3_OUT_28[0]}]
set_property PACKAGE_PIN W6 [get_ports {D3_OUT_29[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports D3_*]
