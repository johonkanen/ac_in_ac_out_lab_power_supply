echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_system_clocks_pkg.vhd

ghdl -a --ieee=synopsys --std=08 source/rtl_counters/rtl_counter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/fpga_interconnect/fpga_interconnect_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/system_register_addresses_pkg.vhd

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
