library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;

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
    procedure blink_led_at
    (
        signal ledstate : std_logic
         
    ) is
    begin
        
    end blink_led_at;

------------------------------------------------------------------------
    procedure count_down_from
    (
        signal downcounter : inout integer;
        max_value_for_counter : integer
    ) is
    begin
        if downcounter > 0 then
            downcounter <= downcounter - 1;
        else
            downcounter <= max_value_for_counter;
        end if;
        
    end count_down_from;

------------------------------------------------------------------------

begin


    led_blinker : process(clock_120Mhz)

        
    begin
        if rising_edge(clock_120Mhz) then

            count_down_from(counter, 10e3);

            if counter = 0 then
                count_down_from(slow_counter, 5e3);
            end if;

            if slow_counter = 0 then
                led_state(0) <= not led_state(0);
            end if;

            if slow_counter = integer(5.0e3/4.0) then
                led_state(1) <= not led_state(1);
            end if;

            if slow_counter = integer(5.0e3/4.0*2.0) then
                led_state(2) <= not led_state(2);
            end if;

            if slow_counter = integer(5.0e3/4.0*3.0) then
                led_state(3) <= not led_state(3);
            end if;

            leds <= led_state;

        end if; --rising_edge
    end process led_blinker;	

end rtl;

