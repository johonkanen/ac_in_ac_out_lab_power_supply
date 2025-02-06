#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

top_lib = VU.add_library("top_lib")
top_lib.add_source_files(ROOT / "source/fpga_communication/signal_scope/signal_scope.vhd")
top_lib.add_source_files(ROOT / "titanium_build/titanium_top.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/uart_protocol_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/fpga_interconnect_16bit_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/serial_protocol_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/communications.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_rx/uart_rx_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_tx/uart_tx_pkg.vhd")

top_lib.add_source_files(ROOT / "source/vhdl_serial/bit_operations_pkg.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/testbench/sample_buffer/sample_trigger_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/dual_port_ram_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/arch_sim_generic_dual_port_ram.vhd")

top_lib.add_source_files(ROOT / "source/fpga_communication/serial_protocol_test_pkg.vhd")

top_lib.add_source_files(ROOT / "simulation/top_tb.vhd")

VU.set_sim_option("nvc.sim_flags", ["-w"])

VU.main()
