library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package system_register_addresses_pkg is

    constant system_control_data_address    : integer := 4096;
    constant power_electronics_data_address : integer := 8192;
    constant sine_address                   : integer := 58;

    constant capacitor_voltage_address : integer := 59;

end package system_register_addresses_pkg;

