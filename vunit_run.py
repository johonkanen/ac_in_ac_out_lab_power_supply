#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

main = VU.add_library("main")
# main.add_source_files(ROOT / "source/fpga_interconnect" / "bus_controller" / "*.vhd")
# main.add_source_files(ROOT / "source/fpga_interconnect" / "*.vhd")
# main.add_source_files(ROOT / "source/fpga_interconnect/interconnect_configuration" / "*.vhd")
# main.add_source_files(ROOT / "source/fpga_interconnect/fpga_interconnect_pkg.vhd")
# main.add_source_files(ROOT / "source/fpga_interconnect/fpga_interconnect_simulation" / "*.vhd")

main.add_source_files(ROOT / "source/system_control/main_state_machine/main_state_machine_pkg.vhd")
# main.add_source_files(ROOT / "source/system_control/main_state_machine/simulate_main_state_machine" / "*.vhd")

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

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm" / "*.vhd")

aux = VU.add_library("spi_adc")
aux.add_source_files(ROOT / "source/adc_interface/spi_sar_adc" / "*.vhd")
aux.add_source_files(ROOT / "source/adc_interface/spi_sar_adc/simulation" / "*.vhd")

VU.main()
