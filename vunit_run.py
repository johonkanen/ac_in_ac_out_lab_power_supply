#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

top_lib = VU.add_library("top_lib")
top_lib.add_source_files(ROOT / "titanium_build/titanium_top.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/uart_protocol_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/uart_protocol_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/fpga_interconnect_16bit_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/serial_protocol_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/communications.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_rx/uart_rx_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/hVHDL_uart/uart_tx/uart_tx_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/signal_scope/signal_scope.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl2008/vhdl2008_microinstruction_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl2008/ram_connector_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl2008/addsub.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl2008/microprogram_sequencer.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl2008/microprogram_processor.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/mpram_w_configurable_records.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/dp_ram_w_configurable_recrods.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/vhdl2008/arch_sim_dp_ram_w_configurable_records.vhd")

top_lib.add_source_files(ROOT / "source/test_processor/uproc_test.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd")

top_lib.add_source_files(ROOT / "source/vhdl_serial/bit_operations_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/spi_adc_generic/spi_adc_type_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/clock_divider/clock_divider_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/vhdl_serial/source/ads7056/ads7056_pkg.vhd")

top_lib.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/testbench/sample_buffer/sample_trigger_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/dual_port_ram_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/arch_sim_generic_dual_port_ram.vhd")

top_lib.add_source_files(ROOT / "simulation/git_hash_pkg.vhd")
top_lib.add_source_files(ROOT / "source/fpga_communication/serial_protocol_test_pkg.vhd")
top_lib.add_source_files(ROOT / "simulation/inu/pwm_pkg.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/division/division_generic_pkg.vhd")

top_lib.add_source_files(ROOT / "source/measurements/measurements.vhd")

top_lib.add_source_files(ROOT / "simulation/top_tb.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/adc_scaler/adc_scaler.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/testbenches/adc_scaler/adc_scaler_tb.vhd")

top_lib.add_source_files(ROOT / "source/main_state_machine/main_state_machine_pkg.vhd")
top_lib.add_source_files(ROOT / "simulation/main_state_machine/main_state_machine_tb.vhd")

top_lib.add_source_files(ROOT / "simulation/ad_interface/psu_measurements_tb.vhd")

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")
aux.add_source_files(ROOT / "simulation/tb_aux_pwm.vhd")

sdm = VU.add_library("sdm")
sdm.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_simulation_model_pkg.vhd")
sdm.add_source_files(ROOT / "source/hVHDL_analog_to_digital_drivers/sigma_delta/sigma_delta_cic_filter_pkg.vhd")
sdm.add_source_files(ROOT / "simulation/sigma_delta_tb.vhd")
sdm.add_source_files(ROOT / "simulation/sigma_delta_rtl_tb.vhd")

pwm = VU.add_library("pwm")
pwm.add_source_files(ROOT / "simulation/inu/pwm_pkg.vhd")
pwm.add_source_files(ROOT / "simulation/inu/inu_pwm_tb.vhd")
pwm.add_source_files(ROOT / "simulation/dab/dab_pwm_tb.vhd")

# ode = VU.add_library("ode")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/write_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/real_vector_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/ode_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/adaptive_ode_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/ode_solvers/sort_pkg.vhd")

top_lib.add_source_files(ROOT / "source/hVHDL_ode/testbenches/lcr_models_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_ode/testbenches/lcr_3ph_tb.vhd")
top_lib.add_source_files(ROOT / "simulation/dab/dab_simulation_tb.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/pi_controller/pi_controller_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")

top_lib.add_source_files(ROOT / "simulation/sw_model_generic_pkg.vhd")
top_lib.add_source_files(ROOT / "simulation/inu/half_bridge_tb.vhd")

top_lib.add_source_files(ROOT / "simulation/inu/grid_inverter_model_pkg.vhd")
top_lib.add_source_files(ROOT / "simulation/inu/grid_inverter_model_tb.vhd")

top_lib.add_source_files(ROOT / "simulation/inu/grid_inverter_control_rtl_tb.vhd")

#--------------------------------------
s7 = VU.add_library("s7")
# s7.add_source_files(ROOT / "spartan7/testbench/measurements_tb.vhd")
s7.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/dual_port_ram_generic_pkg.vhd")
s7.add_source_files(ROOT / "source/hVHDL_memory_library/fpga_internal_ram/arch_sim_generic_dual_port_ram.vhd")

s7.add_source_files(ROOT / "source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")
s7.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_generic_pkg.vhd")

s7.add_source_files(ROOT / "source/fpga_communication/fpga_interconnect_16bit_pkg.vhd")
s7.add_source_files(ROOT / "source/fpga_communication/hVHDL_fpga_interconnect/fpga_interconnect_generic_pkg.vhd")

s7.add_source_files(ROOT / "source/vhdl_serial/bit_operations_pkg.vhd")
s7.add_source_files(ROOT / "source/vhdl_serial/source/spi_adc_generic/spi_adc_type_generic_pkg.vhd")
s7.add_source_files(ROOT / "source/vhdl_serial/source/clock_divider/clock_divider_generic_pkg.vhd")
s7.add_source_files(ROOT / "source/vhdl_serial/source/max11115/max11115_generic_pkg.vhd")

# s7.add_source_files(ROOT / "spartan7/measurements.vhd")

# VU.set_sim_option("nvc.sim_flags", ["-w"])

VU.main()
