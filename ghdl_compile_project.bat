echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_system_clocks_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/math_library/multiplier/multiplier_base_types_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_18x18 source/math_library/multiplier/multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/math_library/multiplier/multiplier_base_types_22bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_22x22 source/math_library/multiplier/multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/math_library/multiplier/multiplier_base_types_26bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 --work=math_library_26x26 source/math_library/multiplier/multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/testi/test_multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/system_register_addresses_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/testi/test_multiplier_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/rtl_counters/rtl_counter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/fpga_interconnect/fpga_interconnect_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/testi/long_multiplier_pkg.vhd

            ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd
            ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd
        ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_transreceiver/uart_transreceiver_pkg.vhd
    ghdl -a --ieee=synopsys --std=08 %source%/uart/uart_pkg.vhd

rem ghdl -a --ieee=synopsys --std=08 source/system_control/mock_component_interconnect_pkg.vhd
        ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/communications/communications_pkg.vhd

        ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/power_electronics/power_electronics_pkg.vhd
    ghdl -a --ieee=synopsys --std=08 source/system_control/component_interconnect/component_interconnect_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/system_control/system_component_interface_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/system_control/system_control_pkg.vhd
