library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package rtl_counter_pkg is
------------------------------------------------------------------------
    procedure count_down_from (
        signal downcounter : inout integer;
        max_value_for_counter : integer);
------------------------------------------------------------------------
    procedure blink_leds (
        led_counter : in integer;
        signal blinking_led : inout std_logic;
        constant blink_led_at : in real);

end package rtl_counter_pkg;

package body rtl_counter_pkg is

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
    procedure blink_leds
    (
        led_counter : in integer;
        signal blinking_led : inout std_logic;
        constant blink_led_at : in real
    ) is
    begin

        if led_counter = integer(blink_led_at) then
            blinking_led <= not blinking_led;
        end if;
        
    end blink_leds;
------------------------------------------------------------------------
end package body rtl_counter_pkg;
