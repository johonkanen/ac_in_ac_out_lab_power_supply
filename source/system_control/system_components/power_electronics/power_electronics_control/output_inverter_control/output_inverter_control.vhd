library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.output_inverter_control_pkg.all;

entity output_inverter_control is
    port (
        output_inverter_control_clocks : in output_inverter_control_clock_record; 
        output_inverter_control_FPGA_in : in output_inverter_control_FPGA_input_record;
        output_inverter_control_FPGA_out : out output_inverter_control_FPGA_output_record; 
        output_inverter_control_data_in : in output_inverter_control_data_input_record;
        output_inverter_control_data_out : out output_inverter_control_data_output_record
    );
end entity output_inverter_control;

architecture rtl of output_inverter_control is

    alias leds is output_inverter_control_FPGA_out.leds;

    signal counter : integer range 0 to 2**16-1 := 0; 
    signal slow_counter : integer range 0 to 2**16-1 := 0; 
    signal led_state : std_logic := '1';

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

begin


    led_blinker : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then
            leds <= (others => led_state);

            count_down_from(counter, 10e3);

            if counter = 0 then
                count_down_from(slow_counter, 5e3);
            end if;

            if slow_counter = 0 then
                led_state <= not led_state;
            end if;

        end if; --rising_edge
    end process led_blinker;	


end rtl;
