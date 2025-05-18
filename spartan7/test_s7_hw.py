
import os
import sys
from scipy.stats import linregress

abs_path = os.path.dirname(os.path.realpath(__file__))
sys.path.append(abs_path + '/../source/fpga_communication/fpga_uart_pc_software/')

from uart_communication_functions import *

comport = sys.argv[1]
linkspeed = eval(sys.argv[2])

uart = uart_link(comport, linkspeed)

print("test data from address 1 :")
print(uart.request_data_from_address(1))

def get(address):
    return uart.request_data_from_address(address)

def set(address, data):
    uart.write_data_to_address(address, int(data))
    print(uart.request_data_from_address(address))
