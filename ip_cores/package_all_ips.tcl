#*****************************************************************************************
# package_all_ips.tcl
#
# Re-empaqueta los IP cores propios del MicroZohm escritos en VHDL a mano a partir de sus
# fuentes en <ip_cores>/mz_<nombre>_1.0/hdl/. El resultado (component.xml + xgui/) queda en
# la misma carpeta, de forma que vivado/build.tcl solo necesita apuntar a ip_cores/.
#
# Convenio: carpeta mz_<nombre>_<version>, VLNV microzohm:user:mz_<nombre>:<version>,
# entidad top mz_<nombre>, ficheros hdl/mz_<nombre>*.vhd (esclavo AXI: *_s00_axi.vhd).
#
# MZ_ADC_LTC2311_3.0 y MZ_AXI2TCM_1.1 NO se regeneran con este script: vienen empaquetados
# del framework UltraZohm (se les cambio vendor, nombre y ficheros; las entidades VHDL
# conservan su nombre original).
#
# Uso (desde la consola Tcl de Vivado o en batch):
#   cd <mz-sw>/ip_cores
#   source package_all_ips.tcl
#
# Solo hace falta ejecutarlo cuando se modifica el VHDL de alguno de estos IPs.
#*****************************************************************************************

set ip_repo_dir [file normalize [file dirname [info script]]]
set part        "xczu9eg-ffvc900-1-e"
set vendor      "microzohm"
set library     "user"
set version     "1.0"

# Lista de IPs: {carpeta  entidad_top  nombre_visible  puertos_que_NO_son_reloj  asociaciones}
#  - puertos_que_NO_son_reloj: señales de datos cuyo nombre contiene "clk"/"clock" y que
#    Vivado inferiría erróneamente como interfaz de reloj.
#  - asociaciones: lista de {reloj  bus_axi|""  reset|""} para declarar explícitamente qué
#    reloj/reset pertenece a cada interfaz AXI (evita que la inferencia elija mal).
#  - driver (opcional): nombre de la carpeta en <ip>/drivers/ con el driver de Vitis
#    (data/*.mdd, data/*.tcl, src/*). Se incluye en el IP para que el XSA lo exporte y
#    xparameters.h conserve los nombres XPAR_<inst>_S00_AXI_BASEADDR del proyecto original.
set ip_list {
    {MZ_AXI_PWM_1.0            MZ_AXI_PWM            "MicroZohm AXI PWM"                               {}
        {{s00_axi_aclk s00_axi s00_axi_aresetn}}}
    {MZ_AXI_PHASE_DETECTOR_1.0 MZ_AXI_PHASE_DETECTOR "MicroZohm AXI phase detector"                     {}
        {{s00_axi_aclk s00_axi s00_axi_aresetn}}}
    {MZ_CLOCK_FLAG_DIV_1.0     MZ_CLOCK_FLAG_DIV     "MicroZohm clock flag divider (trigger ADC)"       {clock_base_2sync clk_output}
        {{s00_axi_aclk s00_axi s00_axi_aresetn}} MZ_CLOCK_FLAG_DIV_v1_0}
    {MZ_AVERAGER_8CH_1.0       MZ_AVERAGER_8CH       "MicroZohm averager 8 canales ADC"                 {clock_base_2sync}
        {{clk "" resetn}}}
    {MZ_ADC_MAX11331_1.0       MZ_ADC_MAX11331       "MicroZohm ADC MAX11331 (A3, slow ADC)"            {}
        {{s_axi_lite_aclk s_axi_lite s_axi_lite_aresetn} {clk "" reset_n}}}
    {MZ_CLOCK_DIV_1.0          MZ_CLOCK_DIV          "MicroZohm clock divider (clk / DIVIDER, AXI)"     {clk_out}
        {{s00_axi_aclk s00_axi s00_axi_aresetn} {clk "" resetn}}}
    {MZ_IOBUFDS_1.0            MZ_IOBUFDS            "MicroZohm LVDS buffers (IBUFDS/OBUFDS) for the LTC2311 SPI" {SCLK_IN SCLK_OUT}
        {}}
    {MZ_DELAY_TRIGGER_1.0      MZ_DELAY_TRIGGER      "MicroZohm programmable delay line (trigger)"      {}
        {}}
    {MZ_EXTEND_INTERRUPT_1.0   MZ_EXTEND_INTERRUPT   "MicroZohm interrupt pulse stretcher"              {}
        {}}
    {MZ_INTERLOCK_3L_1.0       MZ_INTERLOCK_3L       "MicroZohm interlock and dead time (3 level NPC)"  {}
        {}}
}

set tmp_dir [file normalize "$ip_repo_dir/.tmp_pkg"]

foreach ip $ip_list {
    lassign $ip folder top display_name data_ports assocs driver
    set ip_dir "$ip_repo_dir/$folder"
    puts "\n=== Empaquetando $top  ->  $ip_dir ==="

    # Proyecto temporal solo con las fuentes del IP
    file delete -force $tmp_dir
    create_project -force tmp_pkg $tmp_dir -part $part
    set_property target_language VHDL [current_project]
    add_files -norecurse [glob "$ip_dir/hdl/*.vhd"]
    set_property top $top [current_fileset]
    update_compile_order -fileset sources_1

    # Empaquetar in-place (sin copiar fuentes) y quedarnos con el core abierto
    ipx::package_project -root_dir $ip_dir -vendor $vendor -library $library \
        -taxonomy /UserIP -import_files false -force
    set core [ipx::current_core]

    set_property name          [string map {_1.0 ""} $folder] $core
    set_property display_name  $display_name $core
    set_property description   $display_name $core
    set_property version       $version $core
    set_property core_revision 1 $core
    set_property supported_families {zynquplus Production} $core

    # Puertos de datos que Vivado infirió como reloj -> quitar la interfaz
    foreach p $data_ports {
        if {[llength [ipx::get_bus_interfaces $p -of_objects $core]] > 0} {
            ipx::remove_bus_interface $p $core
            puts "    quitada interfaz de reloj inferida en puerto '$p'"
        }
    }

    # Asociar explícitamente reloj <-> bus AXI <-> reset.
    # Primero se borran las asociaciones inferidas (pueden elegir el reloj equivocado).
    foreach clkif [ipx::get_bus_interfaces -of_objects $core -filter {BUS_TYPE_NAME == clock}] {
        foreach pname {ASSOCIATED_BUSIF ASSOCIATED_RESET} {
            set prm [ipx::get_bus_parameters $pname -of_objects $clkif]
            if {[llength $prm] > 0} { ipx::remove_bus_parameter $pname $clkif }
        }
    }
    foreach a $assocs {
        lassign $a clk busif rst
        if {$busif eq "" && $rst eq ""} { continue }
        set args [list -clock $clk]
        if {$busif ne ""} { lappend args -busif $busif }
        if {$rst   ne ""} { lappend args -reset $rst }
        ipx::associate_bus_interfaces {*}$args $core
    }

    # Driver de Vitis + parametros C_S00_AXI_BASEADDR/HIGHADDR ligados al bloque de
    # direcciones (igual que hace la plantilla "Create and Package IP" de Vivado)
    if {$driver ne ""} {
        foreach {pname pval} {C_S00_AXI_BASEADDR 0xFFFFFFFF C_S00_AXI_HIGHADDR 0x00000000} {
            set prm [ipx::add_user_parameter $pname $core]
            set_property value_resolve_type    user      $prm
            set_property value_format          bitString $prm
            set_property value_bit_string_length 32      $prm
            set_property value                 $pval     $prm
            set_property enablement_value      false     $prm
        }
        set ab [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s00_axi -of_objects $core]]
        set_property value C_S00_AXI_BASEADDR [ipx::add_address_block_parameter OFFSET_BASE_PARAM $ab]
        set_property value C_S00_AXI_HIGHADDR [ipx::add_address_block_parameter OFFSET_HIGH_PARAM $ab]

        set fg [ipx::add_file_group -type software_driver {} $core]
        foreach f [glob -directory "$ip_dir/drivers/$driver" -type f "data/*" "src/*"] {
            set rel "drivers/$driver/[file tail [file dirname $f]]/[file tail $f]"
            set fobj [ipx::add_file $rel $fg]
            switch -glob -- [file tail $f] {
                *.mdd     { set_property type {mdd driver_mdd}       $fobj }
                *.tcl     { set_property type {tclSource driver_tcl} $fobj }
                Makefile  { set_property type {driver_src}           $fobj }
                *.c - *.h { set_property type {cSource driver_src}   $fobj }
            }
        }
        puts "    driver '$driver' incluido en el IP"
    }

    ipx::create_xgui_files $core
    ipx::update_checksums  $core
    ipx::check_integrity   $core
    ipx::save_core         $core
    ipx::unload_core       $core
    close_project

    puts "=== OK: $vendor:$library:[string map {_1.0 ""} $folder]:$version"
}

file delete -force $tmp_dir
puts "\nTodos los IPs empaquetados en $ip_repo_dir"
