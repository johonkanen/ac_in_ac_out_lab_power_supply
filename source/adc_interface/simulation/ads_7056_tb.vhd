LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.clock_divider_pkg.all;
    use work.ads7056_pkg.all;

entity ads_7056_new_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of ads_7056_new_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 250;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal clock_divider : clock_divider_record := init_clock_divider(7);
    signal divided_clock : std_logic;
    signal chip_select : std_logic := '0';
    signal chip_select1 : std_logic := '0';
    signal output : std_logic := '0';

    function "and"
    (
        left : boolean;
        right : std_logic 
    )
    return std_logic 
    is
        variable value : std_logic;
    begin
        if left and right = '0' then
            value := '0';
        else
            value := '1';
        end if;
        return value;
            
    end "and";

    signal ads7056 : ads7056_record := init_ads7056(7);

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

            create_ads7056(ads7056, '1');
            create_clock_divider(clock_divider);
            divided_clock <= get_divided_clock(clock_divider);

            output <= '1';
            chip_select <= '1';
            if simulation_counter = 15 then 
                request_clock_divider(clock_divider, 24);
                initialize_ads7056(ads7056);
                chip_select <= '0';
                output <= '0';
            end if;

            if clock_divider.clock_counter > 0 then
                chip_select <= '0';
            end if;
            chip_select1 <= chip_select;

            output <= (clock_divider.clock_counter > 0) and chip_select;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
