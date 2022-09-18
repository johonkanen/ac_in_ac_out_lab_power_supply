echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source/hVHDL_floating_point

ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_type_definitions/float_word_length_16_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_type_definitions/float_type_definitions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/normalizer/normalizer_configuration/normalizer_with_4_stage_pipe_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/normalizer/normalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/denormalizer/denormalizer_configuration/denormalizer_with_4_stage_pipe_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/denormalizer/denormalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_to_real_conversions/float_to_real_functions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_to_real_conversions/float_to_real_conversions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_adder/float_adder_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_multiplier/float_multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_alu/float_alu_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_first_order_filter/float_first_order_filter_pkg.vhd

SET source=%project_root%/source/

ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/adc_interface/clock_divider_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/adc_interface/ads7056_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/adc_interface/spi_sar_adc/spi_sar_adc_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/adc_interface/spi_sar_adc/ads7056_driver.vhd

ghdl -a --ieee=synopsys --std=08 %source%/aux_pwm/aux_pwm_pkg.vhd

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_system_clocks_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_configuration/ram_configuration_16x1024_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/hVHDL_memory_library/fpga_ram/ram_write_port_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/sincos/lut_generator_functions/sine_lut_generator_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/hVHDL_math_library/sincos/lut_sine_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/hVHDL_math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/hVHDL_math_library/multiplier/multiplier_base_types_26bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/hVHDL_math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/hVHDL_dynamic_model_verification_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/hVHDL_dynamic_model_verification_library/lcr_filter_model/lcr_filter_model_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/hVHDL_dynamic_model_verification_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/hVHDL_dynamic_model_verification_library/lcr_filter_model/lcr_filter_model_pkg.vhd


ghdl -a --ieee=synopsys --std=08 source/system_register_addresses_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/rtl_counters/rtl_counter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/hVHDL_fpga_interconnect/interconnect_configuration/data_15_address_15_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/hVHDL_fpga_interconnect/fpga_interconnect_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_transreceiver_data_type_16_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_transreceiver/uart_transreceiver_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_uart/uart_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/system_control/communications/communications.vhd

ghdl -a --ieee=synopsys --std=08 source/system_control/main_state_machine/main_state_machine_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/system_control/power_electronics/power_electronics.vhd

ghdl -a --ieee=synopsys --std=08 source/system_control/main_state_machine/main_state_machine_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/system_control/system_control.vhd

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_top.vhd
ghdl -a --ieee=synopsys --std=08 cyclone10_build/cyclone_10_top.vhd
