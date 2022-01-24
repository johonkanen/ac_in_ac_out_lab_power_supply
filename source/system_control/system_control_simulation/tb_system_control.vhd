LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library work;
    use work.system_component_interface_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_system_control is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_system_control is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type system_states is (wait_for_run_command, init, normal_operation, power_down, fault, acknowledge_fault);
    signal main_state_machine : system_states := wait_for_run_command;

    procedure change_state
    (
        signal state_machine : out system_states;
        change_state_to : system_states
    ) is
    begin

        state_machine <= change_state_to;
    end change_state;

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

            CASE main_state_machine is
                WHEN wait_for_run_command => 
                    change_state(main_state_machine , init);

                WHEN init => 
                    change_state(main_state_machine , normal_operation);

                WHEN normal_operation => 
                    change_state(main_state_machine , power_down);

                WHEN power_down => 
                    change_state(main_state_machine , fault);

                WHEN fault => 
                    change_state(main_state_machine , acknowledge_fault);

                WHEN acknowledge_fault => 
                    change_state(main_state_machine , wait_for_run_command);

            end CASE; --main_state_machine

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
