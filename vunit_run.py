#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mult = VU.add_library("mult");
mult.add_source_files(ROOT / "source/hVHDL_math_library/multiplier" / "multiplier_base_types_18bit_pkg.vhd")
mult.add_source_files(ROOT / "source/hVHDL_math_library/multiplier" / "multiplier_pkg.vhd")
mult.add_source_files(ROOT / "source/hVHDL_math_library/sincos" / "sincos_pkg.vhd")

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm" / "*.vhd")

aux = VU.add_library("spi_adc")
aux.add_source_files(ROOT / "source/adc_interface/" / "*.vhd")
aux.add_source_files(ROOT / "source/adc_interface/spi_sar_adc" / "*.vhd")
aux.add_source_files(ROOT / "source/adc_interface/spi_sar_adc/simulation" / "*.vhd")

VU.main()
