# MicroZohm minimal (vivado2) - recorte de las constraints originales de mz-sw/vivado/constraints/te0808_mz
# Solo se conservan los puertos que existen en el block design minimo.
# D2: entrada del detector de fase + patron de habilitacion del Safety CPLD (26..29)
set_property PACKAGE_PIN U11  [get_ports {D2_IN_PHASE}]
set_property PACKAGE_PIN AK5  [get_ports {D2_OUT_26[0]}]
set_property PACKAGE_PIN AJ5  [get_ports {D2_OUT_27[0]}]
set_property PACKAGE_PIN AJ4  [get_ports {D2_OUT_28[0]}]
set_property PACKAGE_PIN AH4  [get_ports {D2_OUT_29[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports D2_*]
