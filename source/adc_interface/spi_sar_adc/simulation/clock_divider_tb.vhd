LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity clock_divider_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of clock_divider_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 150;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal rising_edge_is_detected : boolean := false;

    type clock_divider_record is record
        divided_clock : std_logic;
        clock_divider_counter : natural;
        clock_divider_max : natural;
    end record;

    constant init_clock_divider : clock_divider_record := ('1', 0, 1);
------------------------------------------------------------------------
    procedure create_clock_divider
    (
        signal clock_divider_object : inout clock_divider_record
    ) is
        alias m is clock_divider_object;
    begin
        if m.clock_divider_counter > 0 then
            m.clock_divider_counter <= m.clock_divider_counter - 1;
        else
            m.clock_divider_counter <= m.clock_divider_max;
        end if;
        
        if m.clock_divider_counter > m.clock_divider_max/2 then
            m.divided_clock <= '0';
        else
            m.divided_clock <= '1';
        end if;

    end create_clock_divider;
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
    signal clock_divider : clock_divider_record := init_clock_divider;
    signal divided_clock : std_logic;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_clock_divider(clock_divider);
            divided_clock <= get_divided_clock(clock_divider);
            rising_edge_is_detected <= data_delivered_on_rising_edge(clock_divider);


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
