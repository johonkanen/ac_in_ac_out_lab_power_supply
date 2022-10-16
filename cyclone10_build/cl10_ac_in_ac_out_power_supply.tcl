# Copyright (C) 2021  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and any partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details, at
# https://fpgasoftware.intel.com/eula.

# Quartus Prime: Generate Tcl File for Project
# File: cl10_ac_in_ac_out_power_supply.tcl
# Generated on: Sat Jul  2 19:12:44 2022

# Load Quartus Prime Tcl Project package
package require ::quartus::project
package require ::quartus::flow

set fpga_device 10CL025YU256I7G
set output_dir ./output

variable tcl_path [ file dirname [ file normalize [ info script ] ] ] 
puts $tcl_path
set source_path $tcl_path/../source

if {[project_exists cl10_ac_in_ac_out_power_supply]} \
{
    project_open -revision top cl10_ac_in_ac_out_power_supply
} \
else \
{
    project_new -revision top cl10_ac_in_ac_out_power_supply
}

    proc add_vhdl_file_to_project {vhdl_file} {
        set_global_assignment -name VHDL_FILE $vhdl_file
    }

    proc add_vhdl_file_to_library {vhdl_file library} {
        set_global_assignment -name VHDL_FILE $vhdl_file -library $library
    }


	set_global_assignment -name QIP_FILE $tcl_path/cyclone_IP/main_clocks.qip

    source $tcl_path/make_assignments.tcl

    set_global_assignment -name VHDL_FILE $tcl_path/../source/top.vhd
    set_global_assignment -name VHDL_FILE $tcl_path/cyclone_10_top.vhd
    set_global_assignment -name VHDL_FILE $tcl_path/../efinix_build/efinix_system_clocks_pkg.vhd

    source $tcl_path/vhdl_source_files.tcl
    set_global_assignment -name TOP_LEVEL_ENTITY cyclone_top

    set_location_assignment PIN_M2 -to xclk
	set_location_assignment PIN_T6 -to uart_rx
	set_location_assignment PIN_R6 -to uart_tx
	set_location_assignment PIN_N5 -to leds[0]
	set_location_assignment PIN_N6 -to leds[1]
	set_location_assignment PIN_M6 -to leds[2]
	set_location_assignment PIN_P6 -to leds[3]

    set_location_assignment PIN_R11 -to grid_inu_leg1_hi
    set_location_assignment PIN_T10 -to grid_inu_leg1_low
    set_location_assignment PIN_N8  -to grid_inu_leg2_hi
    set_location_assignment PIN_R12 -to grid_inu_leg2_low

    set_location_assignment PIN_R10 -to dab_primary_hi
    set_location_assignment PIN_T7  -to dab_primary_low
    set_location_assignment PIN_R4  -to dab_secondary_hi
    set_location_assignment PIN_R3  -to dab_secondary_low

    set_location_assignment PIN_T3 -to output_inu_leg1_hi
    set_location_assignment PIN_N2 -to output_inu_leg1_low
    set_location_assignment PIN_M7 -to output_inu_leg2_hi
    set_location_assignment PIN_N3 -to output_inu_leg2_low
    
    set_location_assignment PIN_L1  -to primary_bypass_relay
    set_location_assignment PIN_N14 -to secondary_bypass_relay

    set_location_assignment PIN_T12 -to gate_power1_pwm
    set_location_assignment PIN_R13 -to gate_power2_pwm
    set_location_assignment PIN_T11 -to gate_power3_pwm
    set_location_assignment PIN_R5  -to gate_power4_pwm
    set_location_assignment PIN_L2  -to gate_power5_pwm
    set_location_assignment PIN_T4  -to gate_power6_pwm

    set_location_assignment PIN_P16 -to grid_inu_sdm_clock
    set_location_assignment PIN_P1  -to output_inu_sdm_clock
    set_location_assignment PIN_P8  -to dab_sdm_clock

    set_location_assignment PIN_N16 -to grid_inu_sdm_data
    set_location_assignment PIN_N1  -to output_inu_sdm_data
    set_location_assignment PIN_T5  -to dab_sdm_data

    set_location_assignment PIN_P2 -to ads_7056_clock
    set_location_assignment PIN_R1 -to ads_7056_chip_select
    set_location_assignment PIN_T2 -to ads_7056_input_data

    set_location_assignment PIN_R14 -to ads_7056_clock_pri      
    set_location_assignment PIN_T13 -to ads_7056_chip_select_pri
    set_location_assignment PIN_T15 -to ads_7056_input_data_pri 

    set_location_assignment PIN_R16 -to ad_mux1_io[2]
    set_location_assignment PIN_P15 -to ad_mux1_io[1]
    set_location_assignment PIN_T14 -to ad_mux1_io[0]

    set_location_assignment PIN_L16 -to ad_mux2_io[2]
    set_location_assignment PIN_L15 -to ad_mux2_io[1]
    set_location_assignment PIN_N15 -to ad_mux2_io[0]



	export_assignments
    set_global_assignment -name SDC_FILE $tcl_path/cl10_ac_in_ac_out_power_supply.sdc

    execute_flow -compile
