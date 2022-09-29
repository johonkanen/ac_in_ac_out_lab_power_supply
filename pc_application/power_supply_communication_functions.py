import serial
import struct

uart_link = serial.Serial()
uart_link.baudrate = 5e6
uart_link.timeout = 0.1
uart_link.port = "com4"
uart_link.open()
uart_link.reset_input_buffer()
uart_link.reset_output_buffer()

def get_data_from_uart(uart_link_object):
    data_from_uart = uart_link_object.read(5)
    return int.from_bytes(data_from_uart[3:5], "big")

def request_data_from_address(uart_link_object, address):
    uart_message = address | 2 << 16
    uart_link_object.write(uart_message.to_bytes(3, "big"))
    return get_data_from_uart(uart_link_object)

def write_data_to_address(uart_link_object, address, data):
    uart_message = data | address << 16  | 5 << 32
    uart_link_object.write(uart_message.to_bytes(5, "big"))
