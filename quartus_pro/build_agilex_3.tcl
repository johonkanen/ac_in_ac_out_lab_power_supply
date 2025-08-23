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
set_global_assignment -name VHDL_FILE $this_file_path/../source/test_processor/uproc_test.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/main_state_machine/main_state_machine_pkg.vhd
set_global_assignment -name VHDL_FILE $this_file_path/../source/hVHDL_fixed_point/adc_scaler/adc_scaler.vhd


set_global_assignment -name IP_FILE $this_file_path/ip/main_clock/main_clock.ip
set_global_assignment -name IP_FILE $this_file_path/ip/reset_ip/reset_release.ip
set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6D

	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6B
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6A
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6F
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6E
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6G
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6H
	set_global_assignment -name IOBANK_VCCIO 3.3V -section_id 6C
	set_global_assignment -name IOBANK_VCCIO 1.2V -section_id 3A_T
	set_global_assignment -name OPTIMIZATION_MODE BALANCED
	set_global_assignment -name POWER_APPLY_THERMAL_MARGIN ADDITIONAL
	set_global_assignment -name FLOW_ENABLE_HYPER_RETIMER_FAST_FORWARD ON
	set_global_assignment -name BOARD default
	set_global_assignment -name IP_FILE ../ac_in_ac_out_lab_power_supply/quartus_pro/ip/reset_ip/reset_release.ip
	set_instance_assignment -name PARTITION_COLOUR 4289658812 -to testiAg3 -entity testiAg3

	# IOBANK_6F
	set_location_assignment PIN_BJ1 -to uart_rx -comment IOBANK_6F
	# IOBANK_6G
	set_location_assignment PIN_AK2 -to xclk -comment IOBANK_6G
	# IOBANK_6C
	set_location_assignment PIN_B11 -to output_inu_sdm_data -comment IOBANK_6C
	# IOBANK_6C
	set_location_assignment PIN_D3 -to dab_sdm_data -comment IOBANK_6C
	# IOBANK_6H
	set_location_assignment PIN_AC2 -to grid_inu_sdm_data -comment IOBANK_6H
	# IOBANK_6H
	set_location_assignment PIN_E2 -to dab_sdm_clock -comment IOBANK_6H
	# IOBANK_6C
	set_location_assignment PIN_B8 -to grid_inu_sdm_clock -comment IOBANK_6C
	# IOBANK_6H
	set_location_assignment PIN_N2 -to output_inu_sdm_clock -comment IOBANK_6H
	# IOBANK_6C
	set_location_assignment PIN_B19 -to uart_tx -comment IOBANK_6C
	set_instance_assignment -name AUTO_GLOBAL_CLOCK ON -to * -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to grid_inu_sdm_data -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to xclk -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to output_inu_sdm_clock -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to output_inu_sdm_data -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to uart_rx -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to dab_sdm_clock -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to dab_sdm_data -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to uart_tx -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to grid_inu_sdm_clock -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to grid_inu_sdm_clock -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to uart_tx -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to dab_sdm_clock -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to output_inu_sdm_clock -entity testiAg3
	# IOBANK_6A
	set_location_assignment PIN_BN34 -to enet_led -comment IOBANK_6A
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to enet_led -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to enet_led -entity testiAg3
	# IOBANK_6A
	set_location_assignment PIN_BM34 -to enet_led1 -comment IOBANK_6A
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to enet_led1 -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to enet_led1 -entity testiAg3
	# IOBANK_6D
	set_location_assignment PIN_H21 -to ads_7056_chip_select -comment IOBANK_6D
	# IOBANK_6D
	set_location_assignment PIN_D18 -to ads_7056_input_data -comment IOBANK_6D
	# IOBANK_6D
	set_location_assignment PIN_F18 -to ads_7056_clock -comment IOBANK_6D
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux1_io[2] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux1_io[1] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux1_io[0] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux1_io -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ads_7056_clock -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ads_7056_chip_select -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ads_7056_input_data -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux1_io[2] -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux1_io[1] -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux1_io[0] -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 3MA -to ads_7056_clock -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ads_7056_chip_select -entity testiAg3
	# IOBANK_6H
	set_location_assignment PIN_AF1 -to ad_mux2_io[0] -comment IOBANK_6H
	# IOBANK_6H
	set_location_assignment PIN_AG2 -to ad_mux2_io[1] -comment IOBANK_6H
	# IOBANK_6H
	set_location_assignment PIN_AF2 -to ad_mux2_io[2] -comment IOBANK_6H
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux2_io[2] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux2_io[1] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux2_io[0] -entity testiAg3
	set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to ad_mux2_io -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux2_io[2] -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux2_io[1] -entity testiAg3
	set_instance_assignment -name CURRENT_STRENGTH_NEW 6MA -to ad_mux2_io[0] -entity testiAg3
	# Commit assignments
	export_assignments

execute_flow -compile
