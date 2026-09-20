# Analog Adapter Board A1 
# Author: Sebastian Wendel
# Date: 07.07.2023
# All ADC-Pins are 1,8 Volt on Bank64 and Bank65
# Bank64 and Bank65 are High-Performance Banks (HP), only HP pins have the internal 100R termination resistors and support therefore LVDS


## output clock pins
#A1_00_P
set_property PACKAGE_PIN AE13 [get_ports {A1_OUT_CLK[0]}]
#A1_00_N
set_property PACKAGE_PIN AF13 [get_ports {A1_OUT_CLK[1]}]

# slave select
#A1_01_P
set_property PACKAGE_PIN AG13 [get_ports {A1_OUT_CNV_0[0]}]
#A1_01_N
set_property PACKAGE_PIN AH13 [get_ports {A1_OUT_CNV_1[0]}]

###############################################

## input pins from ADC
#ADC4
#A1_02_P
set_property PACKAGE_PIN AD5 [get_ports {A1_IN[6]}]
set_property PACKAGE_PIN AE5 [get_ports {A1_IN[7]}]
#A1_02_N

#ADC8(4)
#A1_03_P
set_property PACKAGE_PIN AK13 [get_ports {A1_IN[14]}]
set_property PACKAGE_PIN AK12 [get_ports {A1_IN[15]}]
#A1_03_N

#ADC3
#A1_04_P
set_property PACKAGE_PIN AD12 [get_ports {A1_IN[4]}]
set_property PACKAGE_PIN AE12 [get_ports {A1_IN[5]}]
#A1_04_N

#ADC7(3)
#A1_05_P
set_property PACKAGE_PIN AD10 [get_ports {A1_IN[12]}]
set_property PACKAGE_PIN AE10 [get_ports {A1_IN[13]}]
#A1_05_N

#ADC2
#A1_06_P
set_property PACKAGE_PIN AB13 [get_ports {A1_IN[2]}]
set_property PACKAGE_PIN AC13 [get_ports {A1_IN[3]}]
#A1_06_N

#ADC6(2)
#A1_07_P
set_property PACKAGE_PIN AH12 [get_ports {A1_IN[10]}]
set_property PACKAGE_PIN AJ12 [get_ports {A1_IN[11]}]
#A1_07_N

#ADC1
#A1_08_P
set_property PACKAGE_PIN AA12 [get_ports {A1_IN[0]}]
set_property PACKAGE_PIN AA11 [get_ports {A1_IN[1]}]
#A1_08_N

#ADC5(1)
#A1_09_P
set_property PACKAGE_PIN AG8 [get_ports {A1_IN[8]}]
set_property PACKAGE_PIN AH8 [get_ports {A1_IN[9]}]
#A1_09_N

############################################

## property standards
set_property IOSTANDARD LVDS [get_ports {A1_OUT_CLK[0]}]
set_property IOSTANDARD LVDS [get_ports {A1_OUT_CLK[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A1_OUT_CNV_1[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {A1_OUT_CNV_0[0]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[15]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[14]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[13]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[12]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[11]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[10]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[9]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[8]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[7]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[6]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[5]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[4]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[3]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[2]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[1]}]
set_property IOSTANDARD LVDS [get_ports {A1_IN[0]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[15]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[14]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[13]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[12]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[11]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[10]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[9]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[8]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[7]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[6]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[5]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[4]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[3]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[2]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[1]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {A1_IN[0]}]

