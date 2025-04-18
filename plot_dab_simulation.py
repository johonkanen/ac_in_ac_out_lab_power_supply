import pandas as pd
import matplotlib.pyplot as plt

vhdl_data = pd.read_csv('./dab_simulation_tb.dat', delim_whitespace=True)

fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)
vhdl_data.plot(ax=axT, x="time", y="T_u0", label="vhdl u0")
vhdl_data.plot(ax=axT, x="time", y="T_vc", label="vhdl vc")
# vhdl_data.plot(ax=axB, x="time", y="B_i0", label="vhdl i0")
vhdl_data.plot(ax=axB, x="time", y="B_ph", label="vhdl phase")
vhdl_data.plot(ax=axB, x="time", y="B_mg", label="vhdl im")
vhdl_data.plot(ax=axB, x="time", y="ctrl", label="control")

plt.show()
plt.close('all')
