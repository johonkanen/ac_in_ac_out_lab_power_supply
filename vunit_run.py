#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

top_lib = VU.add_library("top_lib")
top_lib.add_source_files(ROOT / "titanium_build/titanium_top.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/uart_protocol_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/fpga_interconnect_16bit_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/serial_protocol_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/communications.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_rx/uart_rx_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_tx/uart_tx_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd")

top_lib.add_source_files(ROOT / "source/vhdl_serial/bit_operations_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/spi_adc_generic/spi_adc_type_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/clock_divider/clock_divider_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/ads7056/ads7056_pkg.vhd")

top_lib.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")

top_lib.add_source_files(ROOT / "simulation/git_hash_pkg.vhd")
top_lib.add_source_files(ROOT / "simulation/top_tb.vhd")

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")
aux.add_source_files(ROOT / "simulation/tb_aux_pwm.vhd")

sdm = VU.add_library("sdm")
sdm.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_simulation_model_pkg.vhd")
sdm.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd")
sdm.add_source_files(ROOT / "simulation/sigma_delta_tb.vhd")
sdm.add_source_files(ROOT / "simulation/sigma_delta_rtl_tb.vhd")

pwm = VU.add_library("pwm")
pwm.add_source_files(ROOT / "simulation/inu/inu_pwm_tb.vhd")

ode = VU.add_library("ode")
ode.add_source_files(ROOT / "source/hVHDL_ode/write_pkg.vhd")
ode.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/real_vector_pkg.vhd")
ode.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/ode_pkg.vhd")
ode.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/adaptive_ode_pkg.vhd")

ode.add_source_files(ROOT / "source/hVHDL_ode/testbenches/lcr_models_pkg.vhd")
ode.add_source_files(ROOT / "source/hVHDL_ode/testbenches/lcr_3ph_tb.vhd")

VU.set_sim_option("nvc.sim_flags", ["-w"])

VU.main()
