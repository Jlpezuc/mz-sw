# MicroZohm minimal (vivado2) - recorte de las constraints originales de mz-sw/vivado/constraints/te0808_mz
# Solo se conservan los puertos que existen en el block design minimo.
# A3: MAX11331 (un solo chip: indice [0])
set_property PACKAGE_PIN AF10 [get_ports {A3_IN[0]}]
set_property PACKAGE_PIN AG10 [get_ports {A3_OUT_MOSI[0]}]
set_property PACKAGE_PIN AF8  [get_ports {A3_OUT_CS[0]}]
set_property PACKAGE_PIN AF7  [get_ports {A3_OUT_SCLK[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A3_IN[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A3_OUT_MOSI[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A3_OUT_CS[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A3_OUT_SCLK[0]}]
