#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

main = VU.add_library("main")
main.add_source_files(ROOT / "source/fpga_interconnect/fpga_interconnect_pkg.vhd")
main.add_source_files(ROOT / "source/fpga_interconnect/fpga_interconnect_simulation" / "*.vhd")
main.add_source_files(ROOT / "source/system_control/main_state_machine/main_state_machine_pkg.vhd")
# main.add_source_files(ROOT / "source/system_control/main_state_machine/simulate_main_state_machine/main_state_machine_tb.vhd")

main.add_source_files(ROOT / "source/system_control/main_state_machine/main_state_machine_pkg.vhd")
main.add_source_files(ROOT / "source/system_control/main_state_machine/simulate_main_state_machine" / "*.vhd")

uart = VU.add_library("uart")
uart.add_source_files(ROOT / "source/uart" / "*.vhd")
uart.add_source_files(ROOT / "source/uart/simulation" / "*.vhd")
uart.add_source_files(ROOT / "source/uart/uart_transreceiver" / "*.vhd")
uart.add_source_files(ROOT / "source/uart/uart_transreceiver/uart_rx" / "*.vhd")
uart.add_source_files(ROOT / "source/uart/uart_transreceiver/uart_tx" / "*.vhd")

mult = VU.add_library("mult");
mult.add_source_files(ROOT / "source/math_library/multiplier" / "multiplier_base_types_18bit_pkg.vhd")
mult.add_source_files(ROOT / "source/math_library/multiplier" / "multiplier_pkg.vhd")
mult.add_source_files(ROOT / "source/math_library/sincos" / "sincos_pkg.vhd")

float_library = VU.add_library("float_library")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_type_definitions/float_word_length_16_bit_pkg.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_type_definitions/float_type_definitions_pkg.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_arithmetic_operations/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "normalizer/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "normalizer/simulate_normalizer/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "denormalizer/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "denormalizer/denormalizer_simulation/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "float_to_real_conversions" / "*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_to_real_conversions/float_to_real_simulation" / "*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "float_adder/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_adder/adder_simulation/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "float_multiplier/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_multiplier/float_multiplier_simulation/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "float_alu/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_alu/float_alu_simulation/*.vhd")

float_library.add_source_files(ROOT /"source/vhdl_float" / "float_first_order_filter/*.vhd")
float_library.add_source_files(ROOT /"source/vhdl_float" / "float_first_order_filter/simulate_float_filter/*.vhd")

VU.main()
