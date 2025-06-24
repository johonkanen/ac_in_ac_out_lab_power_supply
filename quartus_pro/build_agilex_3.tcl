# Copyright (C) 2025  Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and any partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, the Altera Quartus Prime License Agreement,
# the Altera IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Altera and sold by Altera or its authorized distributors.  Please
# refer to the Altera Software License Subscription Agreements 
# on the Quartus Prime software download page.

# Quartus Prime: Generate Tcl File for Project
# File: build_testiAg3.tcl
# Generated on: Tue Jun 24 08:08:28 2025

# Load Quartus Prime Tcl Project package
package require ::quartus::project
variable this_file_path [ file dirname [ file normalize [ info script ] ] ] 

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "testiAg3"]} {
		puts "Project testiAg3 is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists testiAg3]} {
		project_open -revision testiAg3 testiAg3
	} else {
		project_new -revision testiAg3 testiAg3
	}
	set need_to_close_project 1
}


set_global_assignment -name TOP_LEVEL_ENTITY testiAg3
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 25.1.0
set_global_assignment -name PROJECT_CREATION_TIME_DATE "21:02:31  MAY 27, 2025"
set_global_assignment -name LAST_QUARTUS_VERSION "25.1.0 Pro Edition"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE A3CZ100BB18AE7S
set_global_assignment -name FAMILY "Agilex 3"
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name VHDL_INPUT_VERSION VHDL_2019
set_global_assignment -name PROJECT_IP_REGENERATION_POLICY NEVER_REGENERATE_IP

set_global_assignment -name VHDL_FILE $this_file_path/testiAg3top.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../titanium_build/titanium_top.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/uart_protocol_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/fpga_interconnect_16bit_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/serial_protocol_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/communications.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/hVHDL_uart/uart_rx/uart_rx_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/hVHDL_uart/uart_tx/uart_tx_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/vhdl_serial/bit_operations_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/vhdl_serial/source/clock_divider/clock_divider_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/vhdl_serial/source/ads7056/ads7056_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/vhdl_serial/source/spi_adc_generic/spi_adc_type_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/aux_pwm/aux_pwm_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../git_hash_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../simulation/inu/pwm_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_memory_library/fpga_internal_ram/arch_rtl_generic_dual_port_ram.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_memory_library/fpga_internal_ram/dual_port_ram_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/multiplier/multiplier_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/pi_controller/pi_controller_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_memory_library/testbench/sample_buffer/sample_trigger_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/fpga_communication/signal_scope/signal_scope.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/fixed_point_scaling/fixed_point_scaling_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/division/division_generic_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/measurements/measurements.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/vhdl2008/vhdl2008_microinstruction_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/vhdl2008/ram_connector_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/vhdl2008/addsub.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/vhdl2008/microprogram_sequencer.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/vhdl2008/microprogram_processor.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/mpram_w_configurable_records.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/dp_ram_w_configurable_recrods.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/arch_rtl_dp_ram_w_configurable_records.vhd

# Commit assignments
export_assignments
