LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.main_state_machine_pkg.all;

entity main_state_machine_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of main_state_machine_tb is

    constant clock_period      : time      := 1 ns;
    constant simtime_in_clocks : integer   := 5000;
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;

    signal main_state_machine : main_state_record := init_main_state;

    alias main_state is main_state_machine.main_state;

    signal idle_was_reached      : boolean := false;
    signal precharge_was_reached : boolean := false;
    signal running_was_reached   : boolean := false;
    signal fault_was_reached     : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;

        check(idle_was_reached      , "idle was not reached");
        check(precharge_was_reached , "precharge was not reached");
        check(running_was_reached   , "running was not reached");
        check(fault_was_reached     , "fault was not reached");

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_main_state_machine(main_state_machine
                ,start_requested    => simulation_counter = 5
                ,precharge_ready    => simulation_counter = 13
                ,fault_detected     => simulation_counter = 23
                ,fault_acknowledged => simulation_counter = 43
            );

            idle_was_reached      <= idle_was_reached or main_state = idle;
            precharge_was_reached <= precharge_was_reached or main_state = precharge;
            running_was_reached   <= running_was_reached or main_state = running;
            fault_was_reached     <= fault_was_reached or main_state = fault;

            if main_state_machine.main_state = fault
            then
                idle_was_reached <= false;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------

end vunit_simulation;
