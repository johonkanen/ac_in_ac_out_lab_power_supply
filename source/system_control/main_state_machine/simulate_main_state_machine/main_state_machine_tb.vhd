LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.main_state_machine_pkg.all;
    use work.fpga_interconnect_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity main_state_machine_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of main_state_machine_tb is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal main_state_machine : main_state_machine_record := init_main_state_machine;
    signal bus_to_main_state_machine : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_main_state_machine : fpga_interconnect_record := init_fpga_interconnect;

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

            create_main_state_machine(main_state_machine, bus_to_main_state_machine, bus_from_main_state_machine);


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
