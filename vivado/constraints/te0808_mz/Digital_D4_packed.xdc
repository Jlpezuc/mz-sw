# MicroZohm minimal (vivado2) - recorte de las constraints originales de mz-sw/vivado/constraints/te0808_mz
# Solo se conservan los puertos que existen en el block design minimo.
# D4: solo patron de habilitacion del Safety CPLD (26..29)
set_property PACKAGE_PIN A10  [get_ports {D4_OUT_26[0]}]
set_property PACKAGE_PIN B10  [get_ports {D4_OUT_27[0]}]
set_property PACKAGE_PIN C11  [get_ports {D4_OUT_28[0]}]
set_property PACKAGE_PIN D11  [get_ports {D4_OUT_29[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports D4_*]
