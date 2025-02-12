LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package sw_model_generic_pkg is
    generic(package event_pkg is new work.sort_generic_pkg generic map(<>));
    use event_pkg.all;

    type sw_states is (hi, lo);
    ----------------------------------
    type buck_sw_model_record is record
        sw_state       : sw_states;
        next_sw_state  : sw_states;
        was_updated    : boolean;
        t_sw           : real;
        duty           : real;
    end record;

    ----------------------------------
    procedure update(variable self : inout buck_sw_model_record; sim_event : inout event_record; step_length : in real);
    ----------------------------------
    function get_modulated(sw_state : sw_states; current_or_voltage : real) return real;
    ------------------------------------------
end package sw_model_generic_pkg;

package body sw_model_generic_pkg is

    ----------------------------------
    procedure update(variable self : inout buck_sw_model_record; sim_event : inout event_record; step_length : in real) is
    begin

        if self.was_updated then
            self.was_updated := false;
        end if;
        
        sim_event.time_until_event := sim_event.time_until_event - step_length;

        if (sim_event.time_until_event) <= 1.0e-16 then
            self.was_updated := true;
            self.sw_state := self.next_sw_state;
            case self.sw_state is
                WHEN hi => 
                    sim_event.time_until_event := self.t_sw * self.duty;
                    self.next_sw_state := lo;
                WHEN lo => 
                    sim_event.time_until_event := self.t_sw * (1.0-self.duty);
                    self.next_sw_state := hi;
            end CASE;
        end if;
    end update;
    ------------------------------------
    function get_modulated(sw_state : sw_states; current_or_voltage : real) return real is
        variable retval : real;
    begin
        CASE sw_state is
            WHEN hi =>
                retval := current_or_voltage;
            WHEN lo =>
                retval := 0.0;
        end CASE;

        return retval;
    end get_modulated;


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
    constant stoptime : real := 30.0e-3;

    type buck_list is (hb1, hb2, hb3, hb4);
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

        variable timestep : real := 0.0;
        variable realtime : real := 0.0;
        variable tsw : real := 1.0/1000.0e3;

        type buck_array is array (natural range <>) of buck_sw_model_record;

        ------------------------------------
        constant buck_init : buck_sw_model_record := (
            sw_state        => hi
            , next_sw_state => lo
            , was_updated   => false
            , duty          => 0.1
            , t_sw          => tsw
        );
        variable buck : buck_array(0 to 3) := (others => buck_init);
        ------------------------------------

        variable sim_events : event_array(0 to 3) := (
            (hb1, 0.0)
            , (hb2, tsw*1.0/4.0)
            , (hb3, tsw*2.0/4.0)
            , (hb4, tsw*3.0/4.0)
        );
        variable u_in   : real := 48.0     ;
        variable i_load : real := 0.0      ;
        variable l      : real := 1.0e-6   ;
        variable c      : real := 640.0e-6 ;

        ------------------------------------
        impure function deriv (t : real; states : real_vector) return real_vector is
            variable retval : real_vector(0 to 4) := (others => 0.0);
        begin

            retval(0) := ( get_modulated(buck(0).sw_state , u_in) - states(0) * 10.0e-3 - states(4) ) * (1.0/l);
            retval(1) := ( get_modulated(buck(1).sw_state , u_in) - states(1) * 10.0e-3 - states(4) ) * (1.0/l);
            retval(2) := ( get_modulated(buck(2).sw_state , u_in) - states(2) * 10.0e-3 - states(4) ) * (1.0/l);
            retval(3) := ( get_modulated(buck(3).sw_state , u_in) - states(3) * 10.0e-3 - states(4) ) * (1.0/l);
            retval(4) := (states(0) + states(1) + states(2) + states(3) - i_load) * (1.0/c);

            return retval;

        end function;
        ------------------------------------
        variable previous_current : real := 0.0;
        variable sampled_current  : real := 0.0;
        ------------------------------------
        procedure rk1 is new generic_rk1 generic map(deriv);
        procedure rk2 is new generic_rk2 generic map(deriv);
        procedure rk4 is new generic_rk4 generic map(deriv);

        variable buck_states : real_vector(0 to 4) := (0.0, 0.0, 0.0, 0.0, 24.0);
        file file_handler : text open write_mode is "half_bridge_tb.dat";

        type pi_control_record is record
            int : real;
            kp : real;
            ki : real;
        end record;

        function create_pi_control(self : pi_control_record; feedback : real; ref : real) return pi_control_record is
            variable retval : pi_control_record := self;
            variable err : real := 0.0;
            variable y : real := 0.0;
        begin
            err := ref - feedback;
            y := err * self.kp + self.int; 
            if y > 1.0 then
            elsif y < 0.0 then
            else 
            end if;

            return retval;

        end create_pi_control;
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
                ,"B_i4"
                ,"step"
                ));
            end if;

            if realtime > 29.8e-3 then
                write_to(file_handler
                        ,(realtime
                        ,buck_states(4) 
                        ,0.0
                        ,0.0
                        ,0.0
                        ,buck_states(0) 
                        ,buck_states(1)
                        ,buck_states(2) 
                        ,buck_states(3) 
                        ,buck_states(3) + buck_states(2) + buck_states(1) + buck_states(0)
                        ,timestep
                    ));
            end if;

            update(buck(0) , sim_events(0) , timestep);
            update(buck(1) , sim_events(1) , timestep);
            update(buck(2) , sim_events(2) , timestep);
            update(buck(3) , sim_events(3) , timestep);

            if buck(0).was_updated or buck(1).was_updated or buck(2).was_updated or buck(3).was_updated then
                timestep := find_smallest(sim_events);
            end if;

            if buck(0).was_updated then
                sampled_current  := (buck_states(0) + previous_current)/2.0;
                previous_current := buck_states(0);
            end if;

            rk4(realtime , buck_states , timestep);

            realtime := realtime + timestep;

            if realtime > 5.0e-3 then 
                buck(0).duty := 0.4979416;
                buck(1).duty := 0.5068687;
                buck(2).duty := 0.51318677;
                buck(3).duty := 0.52354687;
            end if;
            --
            if realtime > 1.0e-3 then 
                i_load := 50.0;
            end if;
            --
            -- if realtime > 1.5e-3 then 
            --     buck(0).t_sw := 1.0/300.0e3;
            --     buck(1).t_sw := 1.0/301.0e3;
            --     buck(2).t_sw := 1.0/302.0e3;
            --     buck(3).t_sw := 1.0/303.0e3;
            -- end if;

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
