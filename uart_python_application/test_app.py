from power_supply_communication_functions import *

def start():
    write_data_to_address(8192,999)

def start(seconds):
    write_data_to_address(8192,999)
    time.sleep(seconds)
    write_data_to_address(8192,0)

def stop():
    write_data_to_address(8192,0)

def print_things():
    print(request_data_from_address(5005))
    print(request_data_from_address(5006))
    print(request_data_from_address(5007))
    print(request_data_from_address(5008))
    print(request_data_from_address(5009))
    print(request_data_from_address(5010))
    print(request_data_from_address(5011))
    print(request_data_from_address(5012))
    print(request_data_from_address(5013))
    print(request_data_from_address(5014))
    print(request_data_from_address(5015))
    print(request_data_from_address(5016))
    print(request_data_from_address(5017))
    print(request_data_from_address(5018))
    print(request_data_from_address(5019))
    print(request_data_from_address(5020))
    print(request_data_from_address(22000))

    print(request_data_from_address(4097))
    write_data_to_address(4097,0)
    print(request_data_from_address(4097))
    write_data_to_address(4097,44252)
    print(request_data_from_address(4097))
    write_data_to_address(4097,30001)
    print(request_data_from_address(4097))

print_things()
plot_data_from_address(60, 200000)
