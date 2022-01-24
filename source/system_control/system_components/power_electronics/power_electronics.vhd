library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;
    use work.rtl_counter_pkg.all;

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

    signal counter : integer range 0 to 2**16-1 := 0; 
    signal slow_counter : integer range 0 to 2**16-1 := 0; 
    signal led_state : std_logic_vector(3 downto 0) := (others => '0');

------------------------------------------------------------------------

begin

------------------------------------------------------------------------
    led_blinker : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then

            leds <= led_state;

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