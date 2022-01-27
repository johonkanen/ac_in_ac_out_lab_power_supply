library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;
    use work.rtl_counter_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;

entity power_electronics is
    port (
        system_clocks              : in system_clocks_record;
        power_electronics_FPGA_in  : in power_electronics_FPGA_input_group;
        power_electronics_FPGA_out : out power_electronics_FPGA_output_group;
        power_electronics_data_in  : in power_electronics_data_input_group;
        power_electronics_data_out : out power_electronics_data_output_group
    );
end entity power_electronics;


architecture rtl of power_electronics is

    alias clock_120Mhz is system_clocks.clock_120Mhz;
    alias leds is power_electronics_FPGA_out.leds;
    alias bus_in is power_electronics_data_in.bus_in;
    alias bus_out is power_electronics_data_out.bus_out;

    signal counter : integer range 0 to 2**16-1 := 0; 
    signal slow_counter : integer range 0 to 2**16-1 := 0; 
    signal led_state : std_logic_vector(3 downto 0) := (others => '0');

    signal data_from_power_electronics : integer range 0 to 2**16-1 := 0;
------------------------------------------------------------------------
    signal system_is_started : boolean := false;

begin

------------------------------------------------------------------------
    led_blinker : process(clock_120Mhz)

    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_out);
            connect_data_to_address(bus_in, bus_out, power_electronics_data_address, data_from_power_electronics);

            if write_to_address_is_requested(bus_in, power_electronics_data_address) and get_data(bus_in) = 1 then
                system_is_started <= true;
            end if;

            if write_to_address_is_requested(bus_in, power_electronics_data_address) and get_data(bus_in) = 0 then
                system_is_started <= false;
            end if;

            if system_is_started then
                leds <= led_state;
            else
                leds <= (others => '0');
            end if;

            count_down_from(counter, 10e3);
            if counter = 0 then
                count_down_from(slow_counter, 4e3);

                blink_leds(slow_counter, led_state(0),(4.0e3/1.0));
                blink_leds(slow_counter, led_state(1),(4.0e3/2.0));
                blink_leds(slow_counter, led_state(2),(4.0e3/3.0));
                blink_leds(slow_counter, led_state(3),(4.0e3/4.0));

            end if;

        end if; --rising_edge
    end process led_blinker;	
------------------------------------------------------------------------
end rtl;
