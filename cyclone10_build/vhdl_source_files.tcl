    add_vhdl_file_to_project $tcl_path/../source/rtl_counters/rtl_counter_pkg.vhd                                                  
    add_vhdl_file_to_project $tcl_path/../source/aux_pwm/aux_pwm_pkg.vhd

    add_vhdl_file_to_project $tcl_path/../source/hvhdl_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd

    add_vhdl_file_to_project $tcl_path/../source/adc_interface/clock_divider_pkg.vhd
    add_vhdl_file_to_project $tcl_path/../source/adc_interface/ads7056_pkg.vhd

    add_vhdl_file_to_project $tcl_path/../source/system_control/main_state_machine/main_state_machine_pkg.vhd                      
    add_vhdl_file_to_project $tcl_path/../source/system_control/system_control.vhd                                                 
    add_vhdl_file_to_project $tcl_path/../source/system_control/power_electronics/power_electronics.vhd     
    add_vhdl_file_to_project $tcl_path/../source/system_control/power_electronics/power_electronics_pkg.vhd 
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_pkg.vhd                                                                 
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart.vhd                                                                     
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_transreceiver_data_type_16_bit_pkg.vhd                                    
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_transreceiver.vhd                                    
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_transreceiver_pkg.vhd                                
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd                                   
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_rx/uart_rx.vhd                                       
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_tx/uart_tx.vhd                                       
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd                                   
    add_vhdl_file_to_project $tcl_path/../source/system_control/communications/communications.vhd           
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_fpga_interconnect/interconnect_configuration/data_15_address_15_bit_pkg.vhd       
    add_vhdl_file_to_project $tcl_path/../source/hVHDL_fpga_interconnect/fpga_interconnect_pkg.vhd                                       
    add_vhdl_file_to_project $tcl_path/../source/system_register_addresses_pkg.vhd                                                 

    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_configuration/ram_configuration_16x1024_pkg.vhd math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd                 math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_write_port_pkg.vhd                math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_base_types_18bit_pkg.vhd                      math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/sincos/lut_generator_functions/sine_harmonics_lut_generator_pkg.vhd math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/sincos/lut_sine_pkg.vhd                                             math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_pkg.vhd                                       math_library_18x18
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd                       math_library_18x18

    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd                      math_library_22x22
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_pkg.vhd                                       math_library_22x22
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd                       math_library_22x22
    add_vhdl_file_to_library $tcl_path/../source/dynamic_simulation_library/state_variable/state_variable_pkg.vhd                 math_library_22x22
    add_vhdl_file_to_library $tcl_path/../source/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd             math_library_22x22

    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_base_types_26bit_pkg.vhd                      math_library_26x26
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/multiplier/multiplier_pkg.vhd                                       math_library_26x26
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd                       math_library_26x26
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_dynamic_model_verification_library/state_variable/state_variable_pkg.vhd                 math_library_26x26
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_dynamic_model_verification_library/lcr_filter_model/lcr_filter_model_pkg.vhd             math_library_26x26

    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_type_definitions/float_word_length_24_bit_pkg.vhd               float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_type_definitions/float_type_definitions_pkg.vhd                 float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/normalizer/normalizer_configuration/normalizer_with_4_stage_pipe_pkg.vhd float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/normalizer/normalizer_pkg.vhd                                         float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/denormalizer/denormalizer_configuration/denormalizer_with_4_stage_pipe_pkg.vhd float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/denormalizer/denormalizer_pkg.vhd                                     float             

    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_to_real_conversions/float_to_real_functions_pkg.vhd             float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_to_real_conversions/float_to_real_conversions_pkg.vhd           float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd       float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_adder/float_adder_pkg.vhd                                       float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_multiplier/float_multiplier_pkg.vhd                             float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_alu/float_alu_pkg.vhd                                           float             
    add_vhdl_file_to_library $tcl_path/../source/hVHDL_floating_point/float_first_order_filter/float_first_order_filter_pkg.vhd             float             
