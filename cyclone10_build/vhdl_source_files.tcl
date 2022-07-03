set_global_assignment -name VHDL_FILE $tcl_path/../efinix_build/efinix_top.vhd
set_global_assignment -name VHDL_FILE $tcl_path/cyclone_10_top.vhd
set_global_assignment -name VHDL_FILE $tcl_path/../efinix_build/efinix_system_clocks_pkg.vhd

    set_global_assignment -name VHDL_FILE $tcl_path/../source/rtl_counters/rtl_counter_pkg.vhd                                                  
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/main_state_machine/main_state_machine_pkg.vhd                      
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/system_control_pkg.vhd                                             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/system_control.vhd                                                 
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/component_interconnect_pkg.vhd              
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/component_interconnect.vhd                  
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/test_module/test_module_pkg.vhd             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/test_module/test_module.vhd                 
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/power_electronics/power_electronics.vhd     
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/power_electronics/power_electronics_pkg.vhd 
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_pkg.vhd                                                                 
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart.vhd                                                                     
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_transreceiver.vhd                                    
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_transreceiver_pkg.vhd                                
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd                                   
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_rx/uart_rx.vhd                                       
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_tx/uart_tx.vhd                                       
    set_global_assignment -name VHDL_FILE $tcl_path/../source/uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd                                   
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/communications/communications_pkg.vhd       
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_control/component_interconnect/communications/communications.vhd           
    set_global_assignment -name VHDL_FILE $tcl_path/../source/fpga_interconnect/interconnect_configuration/data_15_address_15_bit_pkg.vhd       
    set_global_assignment -name VHDL_FILE $tcl_path/../source/fpga_interconnect/fpga_interconnect_pkg.vhd                                       
    set_global_assignment -name VHDL_FILE $tcl_path/../source/system_register_addresses_pkg.vhd                                                 

    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd                 -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/hVHDL_memory_library/fpga_ram/ram_write_port_pkg.vhd                -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_base_types_18bit_pkg.vhd                      -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/sincos/lut_generator_functions/sine_harmonics_lut_generator_pkg.vhd -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/sincos/lut_sine_pkg.vhd                                             -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_pkg.vhd                                       -library math_library_18x18
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/first_order_filter/first_order_filter_pkg.vhd                       -library math_library_18x18

    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_base_types_22bit_pkg.vhd                      -library math_library_22x22
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_pkg.vhd                                       -library math_library_22x22
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/first_order_filter/first_order_filter_pkg.vhd                       -library math_library_22x22
    set_global_assignment -name VHDL_FILE $tcl_path/../source/dynamic_simulation_library/state_variable/state_variable_pkg.vhd                 -library math_library_22x22
    set_global_assignment -name VHDL_FILE $tcl_path/../source/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd             -library math_library_22x22

    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_base_types_26bit_pkg.vhd                      -library math_library_26x26
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/multiplier/multiplier_pkg.vhd                                       -library math_library_26x26
    set_global_assignment -name VHDL_FILE $tcl_path/../source/math_library/first_order_filter/first_order_filter_pkg.vhd                       -library math_library_26x26
    set_global_assignment -name VHDL_FILE $tcl_path/../source/dynamic_simulation_library/state_variable/state_variable_pkg.vhd                 -library math_library_26x26
    set_global_assignment -name VHDL_FILE $tcl_path/../source/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd             -library math_library_26x26

    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_type_definitions/float_word_length_24_bit_pkg.vhd               -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_type_definitions/float_type_definitions_pkg.vhd                 -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/normalizer/normalizer_pkg.vhd                                         -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/denormalizer/denormalizer_pkg.vhd                                     -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_to_real_conversions/float_to_real_functions_pkg.vhd             -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_to_real_conversions/float_to_real_conversions_pkg.vhd           -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd       -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_adder/float_adder_pkg.vhd                                       -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_multiplier/float_multiplier_pkg.vhd                             -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_alu/float_alu_pkg.vhd                                           -library float             
    set_global_assignment -name VHDL_FILE $tcl_path/../source/vhdl_float/float_first_order_filter/float_first_order_filter_pkg.vhd             -library float             
