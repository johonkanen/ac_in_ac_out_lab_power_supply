from matplotlib import pyplot

simulation_time   = []
inductor_current  = []
capacitor_voltage = []

with open('inverter_simulation_results.dat') as f:
    for line in f.readlines():
        line_with_ends_removed = line.strip()
        line_with_separated_contents = line_with_ends_removed.split()
        simulation_time.append(float(toka[0]))
        inductor_current.append(float(toka[1]))
        capacitor_voltage.append(float(toka[2]))

pyplot.plot(simulation_time, inductor_current)
pyplot.plot(simulation_time, capacitor_voltage)
pyplot.show()
