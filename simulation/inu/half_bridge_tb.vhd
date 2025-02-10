LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.buck_sw_model_pkg.all;

package sw_model_generic_pkg is
    generic(package event_pkg is new work.sort_generic_pkg generic map(<>));
    use event_pkg.all;

    type buck_sw_model_record is record
        sw_state       : sw_states;
        next_sw_state  : sw_states;
        buck_sim_event : event_record;
        was_updated    : boolean;
        t_sw           : real;
        duty           : real;
    end record;

    procedure update(variable self : inout buck_sw_model_record; step_length : in real);
    function get_time_until_event(self : buck_sw_model_record) return real;

end package sw_model_generic_pkg;

package body sw_model_generic_pkg is

    procedure update(variable self : inout buck_sw_model_record; step_length : in real) is
    begin

        if self.was_updated then
            self.was_updated := false;
        end if;

        self.buck_sim_event.time_until_event := self.buck_sim_event.time_until_event - step_length;
        if (self.buck_sim_event.time_until_event) < 1.0e-12 then
            self.was_updated := true;
            self.sw_state := self.next_sw_state;
            case self.sw_state is
                WHEN hi => 
                    self.buck_sim_event.time_until_event := self.t_sw * self.duty;
                    self.next_sw_state := lo;
                WHEN lo => 
                    self.buck_sim_event.time_until_event := self.t_sw * (1.0-self.duty);
                    self.next_sw_state := hi;
            end CASE;
        end if;

    end update;
    ------------------------------------
    function get_time_until_event(self : buck_sw_model_record) return real is
    begin

        return self.buck_sim_event.time_until_event;

    end get_time_until_event;

end package body sw_model_generic_pkg;

-------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity half_bridge_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of half_bridge_tb is

    use work.buck_sw_model_pkg.all;
    use work.write_pkg.all;
    use work.ode_pkg.all;

    constant clock_period : time := 1 ns;
    
    signal simulator_clock    : std_logic := '0';
    signal simulation_counter : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal simtime    : real := 0.0;
    constant stoptime : real := 1.0e-3;

    type buck_list is (buck1, buck2);
    package sort_pkg is new work.sort_generic_pkg generic map(buck_list);
    use sort_pkg.all;
    
    package buck_state_pkg is new work.sw_model_generic_pkg generic map(sort_pkg);
    use buck_state_pkg.all;

begin

------------------------------------------------------------------------
    process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simtime >= stoptime;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable timestep : real := 1.0e-9;
        variable realtime : real := 0.0;

        ------------------------------------
        variable buck_sw_model : buck_sw_model_record := (
            sw_state         => hi
            , next_sw_state  => lo
            , buck_sim_event => (buck1, 0.0)
            , was_updated    => true
            , duty           => 10.0/48.0
            , t_sw           => 1.0/500.0e3
        );
        ------------------------------------

        variable u_in   : real := 48.0;
        variable i_load : real := 0.0;
        variable l      : real := 1.0e-6;
        variable c      : real := 100.0e-6;

        alias duty   is buck_sw_model.duty   ;
        alias t_sw   is buck_sw_model.t_sw   ;

        ------------------------------------
        impure function deriv (t : real; states : real_vector) return real_vector is
            variable retval : real_vector(0 to 2) := (others => 0.0);
        begin
            
            retval(0) := deriv_lcr_model( (l,c,i_load) , buck_sw_model.sw_state, states(0), states(1), u_in);
            -- retval(2) := deriv_lcr_model( (l,c,i_load) , buck_sw_state, states(2), states(1), u_in*0.9);
            -- retval(2) := (states(0) - states(2))/2.0e-6;
            retval(1) := (states(0) + states(2) - i_load) * (1.0/c);

            return retval;

        end function;
        ------------------------------------
        variable previous_current : real := 0.0;
        variable sampled_current  : real := 0.0;
        ------------------------------------

        procedure rk1 is new generic_rk1 generic map(deriv);
        procedure rk2 is new generic_rk2 generic map(deriv);
        procedure rk4 is new generic_rk4 generic map(deriv);

        variable buck_states : real_vector(0 to 2) := (0.0, 0.0, 0.0);
        file file_handler : text open write_mode is "half_bridge_tb.dat";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, ("time"
                ,"T_u0"
                ,"T_u1"
                ,"T_u2"
                ,"T_u3"
                ,"B_i0"
                ,"B_i1"
                ,"B_i2"
                ,"B_i3"
                ));
            end if;

            write_to(file_handler
                    ,(realtime
                    ,buck_states(1) 
                    ,0.0
                    ,0.0
                    ,0.0
                    ,buck_states(0) 
                    ,0.0
                    ,sampled_current
                    ,0.0
                ));

            update(buck_sw_model, timestep);
            if buck_sw_model.was_updated then
                timestep := get_time_until_event(buck_sw_model) / 1.0;
                sampled_current  := (buck_states(0) + previous_current)/2.0;
                previous_current := buck_states(0);
            end if;
            rk4(realtime , buck_states , timestep);

            realtime := realtime + timestep;

            duty := 0.5;

            if realtime > 0.6e-3 then duty := 0.1; end if;
            -- if realtime > 2.0e-3 then duty := 0.5; end if;
            -- if realtime > 3.0e-3 then duty := 1.0/u_in; end if;

            simtime <= realtime;

        end if; -- rising_edge

    end process stimulus;	
------------------------------------------------------------------------
    buck_control : process(simulator_clock) is
    begin
        if rising_edge(simulator_clock) then
        end if;
    end process;
------------------------------------------------------------------------
end vunit_simulation;
