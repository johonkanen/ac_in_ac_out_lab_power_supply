#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

aux = VU.add_library("auxiliary_pwm")
aux.add_source_files(ROOT / "source/aux_pwm/aux_pwm_pkg.vhd")
aux.add_source_files(ROOT / "simulation/tb_aux_pwm.vhd")

VU.main()
