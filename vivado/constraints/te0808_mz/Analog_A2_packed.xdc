# Analog Adapter Board A2
# Author: Sebastian Wendel
# Date: 07.07.2023
# All ADC-Pins are 1,8 Volt on Bank64 and Bank65
# Bank64 and Bank65 are High-Performance Banks (HP), only HP pins have the internal 100R termination resistors and support therefore LVDS


## output clock pins
#A2_00_P
set_property PACKAGE_PIN AC7 [get_ports {A2_OUT_CLK[0]}]
#A2_00_N
set_property PACKAGE_PIN AD7 [get_ports {A2_OUT_CLK[1]}]

# slave select
#A2_01_P
set_property PACKAGE_PIN AA8 [get_ports {A2_OUT_CNV_0[0]}]
#A2_01_N
set_property PACKAGE_PIN AA7 [get_ports {A2_OUT_CNV_1[0]}]

####################################

## input pins from ADC
#ADC4
#A2_02_P
set_property PACKAGE_PIN AD9 [get_ports {A2_IN[6]}]
set_property PACKAGE_PIN AE9 [get_ports {A2_IN[7]}]
#A2_02_N

#ADC8(4)
#A2_03_P
set_property PACKAGE_PIN AF6 [get_ports {A2_IN[14]}]
set_property PACKAGE_PIN AF5 [get_ports {A2_IN[15]}]
#A2_03_N

#ADC3
#A2_04_P
set_property PACKAGE_PIN AJ11 [get_ports {A2_IN[4]}]
set_property PACKAGE_PIN AK11 [get_ports {A2_IN[5]}]
#A2_04_N

#ADC7(3)
#A2_05_P
set_property PACKAGE_PIN AB11 [get_ports {A2_IN[12]}]
set_property PACKAGE_PIN AB10 [get_ports {A2_IN[13]}]
#A2_05_N

#ADC2
#A2_06_P
set_property PACKAGE_PIN AC11 [get_ports {A2_IN[2]}]
set_property PACKAGE_PIN AD11 [get_ports {A2_IN[3]}]
#A2_06_N

#ADC6(2)
#A2_07_P
set_property PACKAGE_PIN AB6 [get_ports {A2_IN[10]}]
set_property PACKAGE_PIN AB5 [get_ports {A2_IN[11]}]
#A2_07_N

#ADC1
#A2_08_P
set_property PACKAGE_PIN AH9 [get_ports {A2_IN[0]}]
set_property PACKAGE_PIN AJ9 [get_ports {A2_IN[1]}]
#A2_08_N

#ADC5(1)
#A2_09_P
set_property PACKAGE_PIN AK9 [get_ports {A2_IN[8]}]
set_property PACKAGE_PIN AK8 [get_ports {A2_IN[9]}]
#A2_09_N

##################################

## property standards
set_property IOSTANDARD LVDS [get_ports {A2_OUT_CLK[1]}]
set_property IOSTANDARD LVDS [get_ports {A2_OUT_CLK[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A2_OUT_CNV_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A2_OUT_CNV_1[0]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[15]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[14]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[13]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[12]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[11]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[10]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[9]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[8]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[7]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[6]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[5]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[4]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[3]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[2]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[1]}]
set_property IOSTANDARD LVDS [get_ports {A2_IN[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[15]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[14]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[13]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[12]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[11]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[10]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[9]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[8]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[7]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[6]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[5]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[4]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[3]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[2]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[1]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A2_IN[0]}]

