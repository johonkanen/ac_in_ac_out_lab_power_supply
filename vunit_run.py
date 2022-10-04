#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")
aux.add_source_files(ROOT / "simulation/tb_aux_pwm.vhd")

uart = VU.add_library("uart")
uart.add_source_files(ROOT / "source/hVHDL_fpga_interconnect/interconnect_configuration/data_15_address_15_bit_pkg.vhd")
uart.add_source_files(ROOT / "source/hVHDL_fpga_interconnect/fpga_interconnect_pkg.vhd")

uart.add_source_files(ROOT / "source/hVHDL_uart/uart_transreceiver/uart_rx/uart_rx_pkg.vhd")
uart.add_source_files(ROOT / "source/hVHDL_uart/uart_transreceiver/uart_tx/uart_tx_pkg.vhd")

uart.add_source_files(ROOT / "source/system_control/communications/communications.vhd")

uart.add_source_files(ROOT / "uart_communication_pkg.vhd")
uart.add_source_files(ROOT / "uart_stream_pkg.vhd")

uart.add_source_files(ROOT / "simulation/uart_communication_tb.vhd")
uart.add_source_files(ROOT / "simulation/communications_tb.vhd")
uart.add_source_files(ROOT / "simulation/tb_uart_stream.vhd")
uart.add_source_files(ROOT / "simulation/uart_stream_2_tb.vhd")

testi = VU.add_library("testi")
testi.add_source_file(ROOT / "simulation/tb_test_commands.vhd")


VU.main()
