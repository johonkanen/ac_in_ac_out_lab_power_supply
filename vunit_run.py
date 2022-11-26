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
uart.add_source_files(ROOT / "source/hVHDL_uart/uart_protocol/uart_protocol_pkg.vhd")

uart.add_source_files(ROOT / "source/system_control/communications/communications.vhd")

uart.add_source_files(ROOT / "simulation/uart_communication_tb.vhd")
uart.add_source_files(ROOT / "simulation/communications_tb.vhd")

math_library_22x22 = VU.add_library("math_library_22x22")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_math_library/multiplier/multiplier_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_dynamic_model_verification_library/simulator_engine/simulation_configuration_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_dynamic_model_verification_library/simulator_engine/simulation_pkg.vhd")

math_library_22x22.add_source_files(ROOT / "source/hVHDL_dynamic_model_verification_library/state_variable/state_variable_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_dynamic_model_verification_library/lcr_filter_model/lcr_filter_model_pkg.vhd")

math_library_22x22.add_source_files(ROOT / "simulation/hw_model/grid_inu_tb.vhd")

VU.main()
