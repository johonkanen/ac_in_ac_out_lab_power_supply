import os
import sys
from scipy.stats import linregress

abs_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(abs_path + '/fpga_uart_pc_software/')

from uart_communication_functions import *

comport = sys.argv[1]

uart = uart_link(comport, 5e6)

print("test data from address 1 :")
print(uart.request_data_from_address(1))

pri_dc_link_meas_gain = 57.08/945

def set(address, data):
    uart.write_data_to_address(address, int(data))
    print(uart.request_data_from_address(address))

def get(address):
    return uart.request_data_from_address(address)

def measure_dc_link():
    print("mux_position :")
    set(5,1)

def to_dc_link(data):
    return data*pri_dc_link_meas_gain

def linear_fit(x, y):
    # Perform linear regression
    slope, intercept, r_value, p_value, std_err = linregress(x, y)
    
    # Return the offset (intercept) and gain (slope)
    return intercept, slope

input_voltages = (60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50)
measurements   = (9144, 9127, 9110, 9093, 9077, 9060, 9043, 9026, 9010, 8993, 8976)
in2_meas = (7174, 7190, 7206, 7222, 7239, 7256, 7272, 7287, 7304, 7321, 7337)

offset, gain = linear_fit(input_voltages, measurements)
offset2, gain2 = linear_fit(input_voltages, in2_meas)

def to_input_voltage(data):
    return (data-offset)/gain

def to_bridge_voltage(data):
    return (data-offset2)/gain2
