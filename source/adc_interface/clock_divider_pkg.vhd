library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package clock_divider_pkg is

    type clock_divider_record is record
        divided_clock         : std_logic;
        clock_divider_counter : natural;
        clock_divider_max     : natural;
        clock_clounter        : natural;
    end record;

    constant init_clock_divider : clock_divider_record := ('1', 0, 3, 0);
------------------------------------------------------------------------
    procedure create_clock_divider (
        signal clock_divider_object : inout clock_divider_record);
------------------------------------------------------------------------
    procedure request_clock_divider (
        signal clock_divider_object : inout clock_divider_record;
        number_of_clocks_is : integer);
------------------------------------------------------------------------
    function get_divided_clock ( clock_divider_object : clock_divider_record)
        return std_logic;
------------------------------------------------------------------------
    function data_delivered_on_rising_edge ( clock_divider_object : clock_divider_record)
        return boolean;
------------------------------------------------------------------------
    function data_delivered_on_falling_edge ( clock_divider_object : clock_divider_record)
        return boolean;
------------------------------------------------------------------------
    procedure set_clock_divider (
        signal clock_divider_object : out clock_divider_record;
        clock_divider : in integer range 2 to 1024);
------------------------------------------------------------------------

end package clock_divider_pkg;


package body clock_divider_pkg is

------------------------------------------------------------------------
    procedure create_clock_divider
    (
        signal clock_divider_object : inout clock_divider_record
    ) is
        alias m is clock_divider_object;
    begin
        if m.clock_clounter > 0 then
            if m.clock_divider_counter > 0 then
                m.clock_divider_counter <= m.clock_divider_counter - 1;
            else
                m.clock_divider_counter <= m.clock_divider_max;
            end if;
            
            if m.clock_divider_counter > m.clock_divider_max/2 then
                m.divided_clock <= '1';
            else
                m.divided_clock <= '0';
            end if;
        else
            m.divided_clock         <= '1';
            m.clock_divider_counter <= m.clock_divider_max;
        end if;

        if data_delivered_on_rising_edge(clock_divider_object) then
            if m.clock_clounter > 0 then
                m.clock_clounter <= m.clock_clounter - 1;
            end if;
        end if;

    end create_clock_divider;
------------------------------------------------------------------------
    procedure request_clock_divider
    (
        signal clock_divider_object : inout clock_divider_record;
        number_of_clocks_is : integer
    ) is
    begin
        clock_divider_object.clock_clounter <= number_of_clocks_is;
        clock_divider_object.clock_divider_counter <= clock_divider_object.clock_divider_max;
        clock_divider_object.divided_clock <= '0';

        
    end request_clock_divider;
------------------------------------------------------------------------
    function get_divided_clock
    (
        clock_divider_object : clock_divider_record
    )
    return std_logic 
    is
    begin
        return clock_divider_object.divided_clock;
    end get_divided_clock;
------------------------------------------------------------------------
    function data_delivered_on_rising_edge
    (
        clock_divider_object : clock_divider_record
    )
    return boolean
    is
        alias m is clock_divider_object;
        variable purkka : integer := 0;
    begin
        if m.clock_divider_max > 1 then
            purkka := -1;
        else
            purkka := 1;
        end if;
        return m.clock_divider_counter = m.clock_divider_max/2 + purkka;
    end data_delivered_on_rising_edge;
------------------------------------------------------------------------
    function data_delivered_on_falling_edge
    (
        clock_divider_object : clock_divider_record
    )
    return boolean
    is
        alias m is clock_divider_object;
    begin
        return m.clock_divider_counter = m.clock_divider_max - 1;
    end data_delivered_on_falling_edge;
------------------------------------------------------------------------
    procedure set_clock_divider
    (
        signal clock_divider_object : out clock_divider_record;
        clock_divider : in integer range 2 to 1024
    ) is
    begin
        clock_divider_object.clock_divider_max <= clock_divider;
    end set_clock_divider;
------------------------------------------------------------------------
end package body clock_divider_pkg;
