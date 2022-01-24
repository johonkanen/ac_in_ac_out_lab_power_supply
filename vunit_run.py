#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()
# VU = VUnit.from_argv(vhdl_standard="93")

lib = VU.add_library("lib");
lib.add_source_files(ROOT / "source/uart" / "*.vhd")
lib.add_source_files(ROOT / "source/uart/simulation" / "*.vhd")
lib.add_source_files(ROOT / "source/uart/uart_transreceiver" / "*.vhd")
lib.add_source_files(ROOT / "source/uart/uart_transreceiver/uart_rx" / "*.vhd")
lib.add_source_files(ROOT / "source/uart/uart_transreceiver/uart_tx" / "*.vhd")

# lib.add_source_files(ROOT / "source/system_control" / "*.vhd")
lib.add_source_files(ROOT / "source/system_control/mock_component_interconnect_pkg.vhd")
lib.add_source_files(ROOT / "source/system_control/system_component_interface_pkg.vhd")
lib.add_source_files(ROOT / "source/system_control/mock_component_inteface_body.vhd")
lib.add_source_files(ROOT / "source/system_control/system_control_simulation" / "*.vhd")

VU.main()
