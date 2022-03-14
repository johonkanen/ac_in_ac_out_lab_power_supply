LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library mult;
    use mult.example_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_example is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_example is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 655;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal object : example_record := init_example;
    signal integer_data_from_object : integer := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_example(object);

            if example_is_ready(object) or simulation_counter = 1 then
                request_example(object, simulation_counter*100 mod 65536);
            end if;

            if example_is_ready(object) then
                integer_data_from_object <= get_data(object);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
