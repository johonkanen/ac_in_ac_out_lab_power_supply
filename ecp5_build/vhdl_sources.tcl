
#add_vhdl_file_to_project ../titanium_buil/titanium_top.vhd                                                                       
add_vhdl_file_to_project $source_folder/fpga_communication/hVHDL_uart/uart_rx/uart_rx_pkg.vhd                        
add_vhdl_file_to_project $source_folder/fpga_communication/hVHDL_uart/uart_tx/uart_tx_pkg.vhd                        
add_vhdl_file_to_project $source_folder/fpga_communication/serial_protocol_generic_pkg.vhd                           
add_vhdl_file_to_project $source_folder/fpga_communication/uart_protocol_pkg.vhd                                     
add_vhdl_file_to_project $source_folder/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd 
#add_vhdl_file_to_project $source_folder/fpga_communication/fpga_interconnect_16bit_pkg.vhd                           
add_vhdl_file_to_project $source_folder/vhdl_serial/bit_operations_pkg.vhd                                           
add_vhdl_file_to_project $source_folder/fpga_communication/communications.vhd                                        
add_vhdl_file_to_project $source_folder/vhdl_serial/source/clock_divider/clock_divider_generic_pkg.vhd               
add_vhdl_file_to_project $source_folder/vhdl_serial/source/spi_adc_generic/spi_adc_type_generic_pkg.vhd              
add_vhdl_file_to_project $source_folder/vhdl_serial/source/ads7056/ads7056_pkg.vhd                                   
add_vhdl_file_to_project $source_folder/aux_pwm/aux_pwm_pkg.vhd                                                      
#add_vhdl_file_to_project $source_folder/../git_hash_pkg.vhd                                                                    
add_vhdl_file_to_project $source_folder/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd   
add_vhdl_file_to_project $source_folder/../simulation/inu/pwm_pkg.vhd                                                          
#add_vhdl_file_to_project $source_folder/hVHDL_memory_library/fpga_internal_ram/arch_rtl_generic_dual_port_ram.vhd    
#add_vhdl_file_to_project $source_folder/hVHDL_memory_library/fpga_internal_ram/dual_port_ram_generic_pkg.vhd         
add_vhdl_file_to_project $source_folder/hVHDL_fixed_point/multiplier/multiplier_generic_pkg.vhd                      
add_vhdl_file_to_project $source_folder/hVHDL_fixed_point/pi_controller/pi_controller_generic_pkg.vhd                
add_vhdl_file_to_project $source_folder/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd                        
add_vhdl_file_to_project $source_folder/hVHDL_fixed_point/fixed_point_scaling/fixed_point_scaling_pkg.vhd            
add_vhdl_file_to_project $source_folder/hVHDL_fixed_point/division/division_generic_pkg.vhd                          
#add_vhdl_file_to_project $source_folder/hVHDL_memory_library/testbench/sample_buffer/sample_trigger_generic_pkg.vhd  
#add_vhdl_file_to_project $source_folder/fpga_communication/signal_scope/signal_scope.vhd                             
#add_vhdl_file_to_project $source_folder/measurements/measurements.vhd                                                

add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/source/hVHDL_memory_library/testbench/dual_port_ram/dp_ram_w_configurable_recrods.vhd
add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/source/hVHDL_memory_library/testbench/dual_port_ram/arch_rtl_dp_ram_w_configurable_records.vhd
add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/source/hVHDL_memory_library/testbench/dual_port_ram/mpram_w_configurable_records.vhd
add_vhdl_file_to_project $source_folder/../spartan7/microprogram_pkg.vhd

add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/vhdl2008/vhdl2008_microinstruction_pkg.vhd
add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/vhdl2008/ram_connector_pkg.vhd

add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/testbenches/vhdl2008/retry_microprogram_sequencer.vhd
add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/testbenches/vhdl2008/retry_addsub.vhd
add_vhdl_file_to_project $source_folder/hVHDL_microprogram_processor/testbenches/vhdl2008/retry_microprogram_processor.vhd
