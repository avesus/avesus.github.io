# Native Windows implementation of the existing minimal RTL, without an IP
# integrator project, BSP generation, Vitis, or the version-pinned UHD shell.
set project [file normalize [lindex $argv 0]]
set part [lindex $argv 1]
set out [file normalize [lindex $argv 2]]
set spi_cs [lindex $argv 4]
set host_waveform [lindex $argv 8]
if {$host_waveform eq ""} { set host_waveform 0 }
if {$host_waveform ni {0 1}} { error "Invalid host-waveform build flag" }
set tx_block_ram [lindex $argv 9]
if {$tx_block_ram eq ""} { set tx_block_ram 0 }
if {$tx_block_ram ni {0 1} || ($tx_block_ram && !$host_waveform)} { error "Invalid TX block RAM build flag" }
set counters_to_software [lindex $argv 10]
if {$counters_to_software eq ""} { set counters_to_software 0 }
if {$counters_to_software ni {0 1} || ($counters_to_software && !$tx_block_ram)} { error "Invalid counter-offload build flag" }
set rx_fifo_block_ram [lindex $argv 11]
if {$rx_fifo_block_ram eq ""} { set rx_fifo_block_ram 0 }
if {$rx_fifo_block_ram ni {0 1} || ($rx_fifo_block_ram && !$counters_to_software)} { error "Invalid RX FIFO block RAM flag" }
set single_phase_rx [lindex $argv 12]
if {$single_phase_rx eq ""} { set single_phase_rx 0 }
if {$single_phase_rx ni {0 1} || ($single_phase_rx && !$rx_fifo_block_ram)} { error "Invalid single-phase RX flag" }
set serial_differential [lindex $argv 13]
if {$serial_differential eq ""} { set serial_differential 0 }
if {$serial_differential ni {0 1} || ($serial_differential && !$single_phase_rx)} { error "Invalid serial differential flag" }
set timing_score_ram [lindex $argv 14]
if {$timing_score_ram eq ""} { set timing_score_ram 0 }
if {$timing_score_ram ni {0 1} || ($timing_score_ram && !$serial_differential)} { error "Invalid timing score RAM flag" }
set serial_control_crc [lindex $argv 15]
if {$serial_control_crc eq ""} { set serial_control_crc 0 }
if {$serial_control_crc ni {0 1} || ($serial_control_crc && !$timing_score_ram)} { error "Invalid serial control CRC flag" }
set serial_rx_crc [lindex $argv 16]
if {$serial_rx_crc eq ""} { set serial_rx_crc 0 }
if {$serial_rx_crc ni {0 1} || ($serial_rx_crc && !$serial_control_crc)} { error "Invalid serial RX CRC flag" }
set recursive_correlator [lindex $argv 17]
if {$recursive_correlator eq ""} { set recursive_correlator 0 }
if {$recursive_correlator ni {0 1} || ($recursive_correlator && !$serial_rx_crc)} { error "Invalid recursive correlator flag" }
set peaks_to_software [lindex $argv 18]
if {$peaks_to_software eq ""} { set peaks_to_software 0 }
if {$peaks_to_software ni {0 1} || ($peaks_to_software && !$serial_rx_crc)} { error "Invalid peak offload flag" }
set serial_barker [lindex $argv 19]
if {$serial_barker eq ""} { set serial_barker 0 }
if {$serial_barker ni {0 1} || ($serial_barker && (!$peaks_to_software || $recursive_correlator))} { error "Invalid serial Barker flag" }
set compact_fanout [lindex $argv 20]
if {$compact_fanout eq ""} { set compact_fanout 0 }
if {$compact_fanout ni {0 1} || ($compact_fanout && (!$peaks_to_software || $serial_barker || $recursive_correlator))} { error "Invalid compact serial fanout flag" }
if {$spi_cs ni {0 1}} { error "SPI select must match the installed Linux image (0 or 1)" }
proc check_ps_axi_clocks {} {
    set expected [get_nets -of_objects [get_pins {ps7_i/MAXIGP0ACLK}]]
    if {[llength $expected] != 1} { error "No unique GP0 clock" }
    foreach port {MAXIGP0ACLK MAXIGP1ACLK SAXIGP0ACLK SAXIGP1ACLK SAXIHP0ACLK SAXIHP1ACLK SAXIHP2ACLK SAXIHP3ACLK SAXIACPACLK} {
        set actual [get_nets -of_objects [get_pins ps7_i/$port]]
        if {$actual ne $expected} { error "PS AXI clock $port does not use the running GP0 clock: $actual" }
    }
    puts "E310_PS_AXI_CLOCK_CONTRACT_PASS ports=9 physical_clock_tested=false"
}
if {[lindex $argv 3] eq "inspect"} {
    open_checkpoint [file join $out routed.dcp]
    report_utilization -hierarchical -hierarchical_depth 6 -file [file join $out utilization_hierarchical.rpt]
    report_cdc -details -file [file join $out cdc_details.rpt]
    set ps_report [open [file join $out ps7_connections.rpt] w]
    puts $ps_report "BITSTREAM.CONFIG.UNUSEDPIN=[get_property BITSTREAM.CONFIG.UNUSEDPIN [current_design]]"
    puts "E310_UNUSED_PIN_CONFIGURATION value=[get_property BITSTREAM.CONFIG.UNUSEDPIN [current_design]]"
    foreach pin [get_pins -of_objects [get_cells ps7_i]] {
        puts $ps_report "[get_property NAME $pin] direction=[get_property DIRECTION $pin] nets=[get_nets -quiet -of_objects $pin]"
    }
    foreach port [get_ports -quiet {MIO* DDR* PS_*}] {
        puts $ps_report "TOP [get_property NAME $port] [get_nets -quiet -of_objects $port]"
    }
    close $ps_report
    check_ps_axi_clocks
    exit
}
set rebitgen_source [lindex $argv 6]
if {$rebitgen_source ne "" && $rebitgen_source ne "-"} {
    open_checkpoint $rebitgen_source
    puts "E310_REBITGEN_SAME_ROUTED_LOGIC source=$rebitgen_source"
} else {
if {[lindex $argv 5] eq "1"} {
    # Explicit recovery of the just-created, constrained synthesis checkpoint.
    # Still run optimization, routing, all reports and the timing gates.
    set_param general.maxThreads 8
    open_checkpoint [file join $out synthesized.dcp]
} else {
set hitl [file dirname $project]
set open [file join $project fpga open_e310]
set sifs [file join $hitl wifi_pluto_link fpga_sifs rtl]
set io [file join $hitl wifi_pluto_link fpga_sifs open_xc7]
set control [file join $hitl vendor_uhd_4_9 fpga usrp3 lib control]
set_param general.maxThreads 8
create_project -in_memory -part $part
if {$compact_fanout} { set_property verilog_define {GF_COMPACT_SERIAL_FANOUT} [current_fileset] }
foreach src [list \
    [file join $control synchronizer_impl.v] \
    [file join $control synchronizer.v] \
    [file join $hitl vendor_uhd_4_9 fpga usrp3 top e31x spi_slave.v] \
    [file join $open gf_e310_pmu_regs.sv] \
    [file join $io gf_e310_io_open.sv] \
    [file join $sifs gf_sifs_scheduler.sv] \
    [file join $sifs gf_dsss_1mbps_control_tx.sv] \
    [file join $sifs gf_dsss_sifs_island.sv] \
    [file join $sifs gf_low_mac_classifier.sv] \
    [file join $sifs gf_dsss_sifs_low_mac.sv] \
    [file join $sifs gf_dsss_1mbps_rx.sv] \
    [file join $open gf_serial_mul40.sv] \
    [file join $open gf_serial_differential.sv] \
    [file join $open gf_barker_serial.sv] \
    [file join $open gf_barker_serial_iq.sv] \
    [file join $open gf_barker_radio_bridge.sv] \
    [file join $open gf_e310_serial_clock.sv] \
    [file join $sifs gf_dsss_rx_sifs_ap.sv] \
    [file join $project fpga rtl gf_e31x_sifs_inline.sv] \
    [file join $open gf_e310_async_fifo.sv] \
    [file join $open gf_dsss_1mbps_psdu_tx.sv] \
    [file join $open gf_host_waveform_tx.sv] \
    [file join $open gf_e310_frontend_2g4.sv] \
    [file join $open gf_e310_gp0_regs.sv] \
    [file join $open gf_e310_open_shell_top.sv]] {
    read_verilog -sv $src
}
synth_design -top gf_e310_open_shell_top -part $part -flatten_hierarchy none -generic [list USE_RX_BUFR=1 SPI_CS_INDEX=$spi_cs USE_HOST_WAVEFORM=$host_waveform USE_TX_BLOCK_RAM=$tx_block_ram COUNTERS_TO_SOFTWARE=$counters_to_software RX_FIFO_BLOCK_RAM=$rx_fifo_block_ram SINGLE_PHASE_RX=$single_phase_rx SERIAL_DIFFERENTIAL=$serial_differential TIMING_SCORE_RAM=$timing_score_ram SERIAL_CONTROL_CRC=$serial_control_crc SERIAL_RX_CRC=$serial_rx_crc RECURSIVE_CORRELATOR=$recursive_correlator PEAKS_TO_SOFTWARE=$peaks_to_software SERIAL_BARKER=$serial_barker]
if {$peaks_to_software && [llength [get_cells -quiet -hier -filter {NAME =~ *rx_diagnostic*peak* && IS_SEQUENTIAL == 1}]]} { error "Diagnostic peak tracking remains in FPGA" }
if {$serial_differential && [llength [get_cells -quiet -hier -filter {REF_NAME =~ DSP*}]] != 0} { error "Serial RX unexpectedly retains a DSP" }
if {$timing_score_ram && ![llength [get_cells -quiet -hier -filter {NAME =~ *g_score_ram* && REF_NAME =~ RAM*}]]} { error "Timing scores did not infer RAM" }
write_checkpoint -force [file join $out synthesized_unconstrained.dcp]
# Reuse the same package constraints, excluding nextpnr's BUFG-output clock.
# Vivado propagates its clock from the external input port instead.
set pin_file [open [file join $open e310_open_shell.xdc] r]
set pin_constraints [read $pin_file]
close $pin_file
set removed [regsub -all -line {^create_clock[^\n]*$} $pin_constraints {} pin_constraints]
if {$removed != 1} { error "Expected exactly one nextpnr clock in package constraints" }
eval $pin_constraints
create_clock -name radio_clk -period 25.000 [get_ports CAT_DATA_CLK]
create_clock -name bus_clk -period 10.000 [get_pins {ps7_i/FCLKCLK[0]}]
set_input_jitter bus_clk 0.300
set_input_jitter radio_clk 2.5005
create_generated_clock -name CAT_FB_CLK -multiply_by 1 \
    -source [get_pins ad9361_io/clock_output_ddr/C] [get_ports CAT_FB_CLK]
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks radio_clk] \
    -group [get_clocks bus_clk]
# Same non-clock-capable E310 package input exception as Ettus e31x_pins.xdc.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of_objects [get_pins ad9361_io/radio_clock_buffer/I]]
set capture_buffers [get_cells -hier -filter {REF_NAME == BUFR}]
if {[llength $capture_buffers] != 1} { error "Expected one regional RX capture buffer" }
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -of_objects [get_pins -of_objects $capture_buffers -filter {REF_PIN_NAME == I}]]
# Stock E310 AD9361 delay settings: 4.5 ns programmed data delay. Physical
# setup must confirm these settings before this I/O timing model applies.
foreach edge {rise fall} {
    set extra {}
    if {$edge eq "fall"} { set extra {-clock_fall -add_delay} }
    set_input_delay -clock radio_clk -max 5.7 {*}$extra [get_ports {CAT_P0_D* CAT_RX_FRAME}]
    set_input_delay -clock radio_clk -min 4.5 {*}$extra [get_ports {CAT_P0_D* CAT_RX_FRAME}]
    set_output_delay -clock CAT_FB_CLK -max 5.5 {*}$extra [get_ports {CAT_P1_D* CAT_TX_FRAME}]
    set_output_delay -clock CAT_FB_CLK -min 4.5 {*}$extra [get_ports {CAT_P1_D* CAT_TX_FRAME}]
}
foreach {pin port} [list EMIOSPI0MO CAT_MOSI EMIOSPI0SCLKO CAT_SCLK [format {EMIOSPI0SSON[%d]} $spi_cs] CAT_CS] {
    set_max_delay 10 -from [get_pins ps7_i/$pin] -to [get_ports $port] -datapath_only
    set_min_delay 1 -to [get_ports $port]
}
set_max_delay 10 -from [get_ports CAT_MISO] -to [get_pins ps7_i/EMIOSPI0MI] -datapath_only
set_min_delay 1 -from [get_ports CAT_MISO] -to [get_pins ps7_i/EMIOSPI0MI]
# Preserve Gray pointer coherence independently of the asynchronous clock cut.
foreach {src dst} {write_gray_reg write_gray_read_sync_1_reg read_gray_reg read_gray_write_sync_1_reg gray_radio_reg gray_sync_1_reg} {
    set starts [get_cells -hier -filter "NAME =~ */${src}* && IS_SEQUENTIAL"]
    set ends [get_cells -hier -filter "NAME =~ */${dst}* && IS_SEQUENTIAL"]
    if {[llength $starts] && [llength $ends]} { set_bus_skew 10 -from $starts -to $ends }
}
if {$serial_barker} { source [file join $project tools constrain_barker_radio_bridge.tcl] }
write_checkpoint -force [file join $out synthesized.dcp]
if {[lindex $argv 3] eq "synth"} { puts "E310_CONSTRAINED_SYNTHESIS_PASS hardware_loaded=false";exit 0 }
}
opt_design
place_design
phys_opt_design
route_design
}
check_ps_axi_clocks
set unused_pull [lindex $argv 7]
# The identical routed image passed physical runtime and watchdog/relogin only
# after disabling unused-pin pulls. Do not silently restore Vivado's default.
if {$unused_pull eq "" || $unused_pull eq "-"} { set unused_pull Pullnone }
if {$unused_pull ne "" && $unused_pull ne "-"} {
    if {$unused_pull ni {Pullnone Pulldown}} { error "Unsupported unused-pin setting" }
    set_property BITSTREAM.CONFIG.UNUSEDPIN $unused_pull [current_design]
    puts "E310_EXPLICIT_UNUSED_PIN_CONFIGURATION value=[get_property BITSTREAM.CONFIG.UNUSEDPIN [current_design]]"
}
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $out timing.rpt]
report_utilization -file [file join $out utilization.rpt]
if {$compact_fanout} { report_utilization -hierarchical -hierarchical_depth 6 -file [file join $out utilization_hierarchical.rpt] }
report_cdc -file [file join $out cdc.rpt]
report_bus_skew -file [file join $out bus_skew.rpt]
report_drc -file [file join $out drc.rpt]
if {$serial_barker} { source [file join $project tools check_barker_radio_fanout.tcl] }
write_checkpoint -force [file join $out routed.dcp]
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
if {![llength $setup] || ![llength $hold]} { error "No timed paths" }
if {[get_property SLACK $setup] < 0 || [get_property SLACK $hold] < 0} {
    error "Timing failed; inspect timing.rpt"
}
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force -bin_file [file join $out gf_e310_minimal.bit]
puts "E310_MINIMAL_VIVADO_ROUTE_PASS part=$part hardware_loaded=false"
