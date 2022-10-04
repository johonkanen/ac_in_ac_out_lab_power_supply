import serial
import struct

uart_link = serial.Serial()
uart_link.baudrate = 5e6
uart_link.timeout = 0.1
uart_link.port = "com4"
uart_link.open()
uart_link.reset_input_buffer()
uart_link.reset_output_buffer()

def get_data_from_uart():
    data_from_uart = uart_link.read(5)
    return int.from_bytes(data_from_uart[3:5], "big")

def request_data_from_address(address):
    uart_message = address | 2 << 16
    uart_link.write(uart_message.to_bytes(3, "big"))
    return get_data_from_uart()

def write_data_to_address(address, data):
    uart_message = 4
    uart_link.write(uart_message.to_bytes(1, "big"))
    uart_message = address
    uart_link.write(uart_message.to_bytes(2, "big"))
    uart_message = data 
    uart_link.write(uart_message.to_bytes(2, "big"))
    
def stream_data_from_address(address, number_of_registers):
    uart_message = 5
    uart_link.write(uart_message.to_bytes(1, "big"))
    uart_message = address
    uart_link.write(uart_message.to_bytes(2, "big"))
    uart_message = number_of_registers 
    uart_link.write(uart_message.to_bytes(3, "big"))

    received_stream = [0]
    for i in range(number_of_registers):
        received_stream.append(get_stream_packet_from_uart())

    return received_stream

def get_stream_packet_from_uart():
    data_from_uart = uart_link.read(2)
    return int.from_bytes(data_from_uart, "big")
