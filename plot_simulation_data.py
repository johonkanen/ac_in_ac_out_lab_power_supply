import numpy as np
from matplotlib import pyplot

from PyLTSpice.LTSpiceBatch import SimCommander
from PyLTSpice.LTSpice_RawRead import LTSpiceRawRead
import os
import ltspice
abs_path = os.path.dirname(os.path.realpath(__file__))
SimCommander.setLTspiceRunCommand(SimCommander,"c:/Programs/LTC/LTspiceXVII/XVIIx64.exe")
lcr = SimCommander(abs_path + "./simulation/converter_models/lcr_filter.asc", timeout=20, verbose=False)
lcr.run()
lcr.wait_completion()

d = LTSpiceRawRead(abs_path + "./simulation/converter_models/lcr_filter.raw")

simulation_time   = []
inductor_current  = []
capacitor_voltage = []

with open('inverter_simulation_results.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line_with_ends_removed.split()
        simulation_time.append(float(line_with_separated_contents[0]))
        inductor_current.append(float(line_with_separated_contents[1]))
        capacitor_voltage.append(float(line_with_separated_contents[2]))

pyplot.plot(simulation_time, inductor_current)
pyplot.plot(simulation_time, capacitor_voltage)
pyplot.plot(d.get_trace("time"), d.get_trace("I(L1)"))
pyplot.plot(d.get_trace("time"), d.get_trace("V(capacitor_voltage)"))
pyplot.show()
