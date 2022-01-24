LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library work;
    use work.component_interconnect_pkg.all;
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
    type system_states is (wait_for_run_command, normal_operation, fault, acknowledge_fault);
    signal main_state_machine : system_states := wait_for_run_command;

------------------------------------------------------------------------
    procedure change_state_to
    (
        signal state_machine : out system_states;
        next_state : system_states
    ) is
    begin

        state_machine <= next_state;
    end change_state_to;

------------------------------------------------------------------------
    procedure countdown
    (
        signal countdown_counter : inout integer
    ) is
    begin
        if countdown_counter > 0 then
            countdown_counter <= countdown_counter - 1 ;
        end if;
    end countdown;

------------------------------------------------------------------------
    procedure change_state_to_and_assing_countdown_timer
    (
        signal state_machine     : inout system_states;
        constant next_state      : system_states;
        signal countdown_counter : inout integer;
        state_change_is_requested : boolean
    ) is
    begin
        if state_change_is_requested then
            change_state_to(state_machine , next_state);
            countdown_counter <= 3;
        end if;
        
    end change_state_to_and_assing_countdown_timer;
------------------------------------------------------------------------
    signal counter : integer := 0; 

    signal component_interconnect_data_in : component_interconnect_data_input_group;
    signal component_interconnect_data_out : component_interconnect_data_output_group;

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

    --------------------------------------------------
        procedure create_main_system_control
        (
            signal state_machine : inout system_states;
            signal component_interconnect_input : out component_interconnect_data_input_group;
            component_interconnect_output : in component_interconnect_data_output_group
        ) is
        begin
            CASE state_machine is
                WHEN wait_for_run_command => 

                    if run_is_commanded(component_interconnect_data_out) then
                        change_state_to(state_machine, normal_operation);
                    end if;

                WHEN normal_operation => 

                WHEN fault => 
                    change_state_to_and_assing_countdown_timer(state_machine , acknowledge_fault, counter, counter = 0);

                WHEN acknowledge_fault => 
                    change_state_to_and_assing_countdown_timer(state_machine , wait_for_run_command, counter, counter = 0);

            end CASE; --state_machine

            if trip_is_detected(component_interconnect_output) then
                change_state_to(state_machine , fault);
            end if;
            
        end create_main_system_control;
    --------------------------------------------------

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            component_interconnect_data_out.trigger_trip <= false;
            CASE simulation_counter is
                WHEN 0 => component_interconnect_data_out.start_is_requested <= true;
                WHEN 15 => component_interconnect_data_out.trigger_trip <= true;
                WHEN others => -- do nothign
            end CASE;

            create_main_system_control(main_state_machine, component_interconnect_data_in, component_interconnect_data_out);


            countdown(counter);


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
