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

mult = VU.add_library("mult");
mult.add_source_files(ROOT / "source/math_library/multiplier" / "multiplier_base_types_18bit_pkg.vhd")
mult.add_source_files(ROOT / "source/math_library/multiplier" / "multiplier_pkg.vhd")
mult.add_source_files(ROOT / "source/math_library/sincos" / "sincos_pkg.vhd")

VU.main()
