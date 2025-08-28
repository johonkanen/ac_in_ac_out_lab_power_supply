import os
import sys
from scipy.stats import linregress

##--------------------------------
import struct

# ---- 32-bit float <-> int ----
def float_to_int32(f: float) -> int:
    """Reinterpret a 32-bit float as a 32-bit signed integer."""
    return struct.unpack('!i', struct.pack('!f', f))[0]

def int32_to_float(i: int) -> float:
    """Reinterpret a 32-bit signed integer as a 32-bit float."""
    return struct.unpack('!f', struct.pack('!i', i))[0]
##--------------------------------

abs_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(abs_path + '/source/fpga_communication/fpga_uart_pc_software/')

from uart_communication_functions import *

comport = sys.argv[1]
linkspeed = eval(sys.argv[2])

uart = uart_link(comport, linkspeed, number_of_databytes = 4)

print("test data from address 1 :")
print(uart.request_data_from_address(1))

pri_dc_link_meas_gain = 57.08/945

def stream_data(address, number_of_points):
    uart.request_data_stream_from_address(address, number_of_points)
    return uart.get_streamed_data(number_of_points)

def start_stream(address, number_of_points):
    uart.request_data_stream_from_address(address, number_of_points)

def get_stream(number_of_points):
    return uart.get_streamed_data(number_of_points)

def set(address, data):
    uart.write_data_to_address(address, int(data))

def setf(address, data):
    uart.write_data_to_address(address, float_to_int32(data))

def get(address):
    return uart.request_data_from_address(address)

def getf(address):
    return int32_to_float(uart.request_data_from_address(address))

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
in2_meas       = (7174, 7190, 7206, 7222, 7239, 7256, 7272, 7287, 7304, 7321, 7337)

dc_link_measurements = (947, 930, 913, 896, 879, 862, 845, 828)
dc_link_voltages     = (57.08, 56.07, 55.06, 54.05, 53.05, 52.03, 51.03, 50.02)

offset        , gain        = linear_fit(input_voltages   , measurements)
offset2       , gain2       = linear_fit(input_voltages   , in2_meas)
pri_dc_offset , pri_dc_gain = linear_fit(dc_link_voltages , dc_link_measurements)

def to_input_voltage(data):
    return (data-offset)/gain

def to_bridge_voltage(data):
    return (data-offset2)/gain2

def to_pri_dc_voltage(data):
    return (data-pri_dc_offset)/pri_dc_gain
