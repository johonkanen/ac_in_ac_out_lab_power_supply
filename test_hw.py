import os
import sys

abs_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(abs_path + '/fpga_uart_pc_software/')

from uart_communication_functions import *

comport = sys.argv[1]

uart = uart_link(comport, 5e6)

print("test data from address 1 :")
print(uart.request_data_from_address(1))

def set(address, data):
    uart.write_data_to_address(address, int(data))
    print(uart.request_data_from_address(address))

def get(address):
    return uart.request_data_from_address(address)

def measure_dc_link():
    print("mux_position :")
    set(5,1)

def to_dc_link(data):
    return data/470*60
