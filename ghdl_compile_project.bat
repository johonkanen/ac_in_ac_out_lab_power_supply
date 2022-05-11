echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source/vhdl_float

ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_type_definitions/float_word_length_16_bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_type_definitions/float_type_definitions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/normalizer/normalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/denormalizer/denormalizer_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_to_real_conversions/float_to_real_functions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_to_real_conversions/float_to_real_conversions_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_arithmetic_operations/float_arithmetic_operations_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_adder/float_adder_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_multiplier/float_multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_alu/float_alu_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=float %source%/float_first_order_filter/float_first_order_filter_pkg.vhd

SET source=%project_root%/source/

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_system_clocks_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/math_library/multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/math_library/first_order_filter/first_order_filter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/math_library/multiplier/multiplier_base_types_22bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/math_library/first_order_filter/first_order_filter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/math_library/multiplier/multiplier_base_types_26bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/math_library/first_order_filter/first_order_filter_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/dynamic_simulation_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/dynamic_simulation_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd


ghdl -a --ieee=synopsys --std=08 source/system_register_addresses_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/rtl_counters/rtl_counter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/fpga_interconnect/fpga_interconnect_pkg.vhd

            ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd
            ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd
        ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_transreceiver_pkg.vhd
    ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_pkg.vhd

rem ghdl -a --ieee=synopsys --std=08 source/system_control/mock_component_interconnect_pkg.vhd
        ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/communications/communications_pkg.vhd

        ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/power_electronics/power_electronics_pkg.vhd
        ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/test_module/test_module_pkg.vhd
    ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/component_interconnect_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/system_control/system_control_pkg.vhd
