LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;
    use work.real_to_fixed_pkg.all;

entity dab_simulation_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of dab_simulation_tb is

    constant clock_period      : time    := 1 ns;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal realtime   : real := 0.0;
    constant stoptime : real := 25.0e-3;

    package multiplier_pkg is new work.multiplier_generic_pkg generic map(24,1,1);
    package pi_control_pkg is new work.pi_controller_generic_pkg generic map(multiplier_pkg);
    use multiplier_pkg.all;
    use pi_control_pkg.all;
    
    signal multiplier : multiplier_record := init_multiplier;
    signal pi_controller : pi_controller_record := init_pi_controller(symmetric_limit => 2**15);

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until realtime >= stoptime;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable timestep : real := 1.0e-6;
        variable voltage_over_dab_inductor : real := 0.0;
        type dab_voltage_states is (t0, t1, t2, t3);
        variable st_dab_voltage_states : dab_voltage_states := t0;
        variable next_st_dab_voltage_states : dab_voltage_states := t0;

        variable tsw     : real := 1.0/135.0e3;
        variable phase   : real := 0.0;
        variable phi     : real := tsw/4.0*phase;
        variable phi_old : real := tsw/4.0*phase;
        variable phi_new : real := tsw/4.0*phase;

        variable iload : real := 0.0;

        variable dab_inductor : real := 10.0e-6;

        variable lpri : real := 8.0e-6;
        variable lsec : real := 8.0e-6;
        variable lm   : real := 200.0e-6;

        variable output_capacitor      : real := 100.0e-6;
        variable half_bridge_capacitor : real := 4.0e-6;

        variable uin : real := 200.0;

        -- states = ac inductor, output capacitor, hb upper capacitor, hb lower capacitor
        constant ipri : natural := 0;
        constant uout : natural := 1;
        constant isec : natural := 6;
        constant im   : natural := 7;
        constant usec_upper   : natural := 4;
        constant usec_lower   : natural := 5;

        constant sec_lower_cap   : natural := 2;
        constant sec_upper_cap   : natural := 3;
        variable state_variables : real_vector(0 to 7) := (
              0 => 0.0    -- ac inductor
            , 1 => 200.0  -- output capacitor
            , 2 => 200.0  -- pri upper capacitor
            , 3 => 200.0  -- pri lower capacitor
            , 4 => 200.0  -- sec upper capacitor
            , 5 => 200.0  -- sec lower capacitor
            , 6 => 0.0  -- isec
            , 7 => 0.0  -- lm
        );

        variable sw1_current   : real := 0.0;
        variable load_resistor : real := 2000.0;

        variable i_n : real := 0.0;

        impure function next_timestep return real is
            variable step_length : real := 1.0;
        begin
            st_dab_voltage_states := next_st_dab_voltage_states;
            phi := tsw/4.0*phase;
            CASE st_dab_voltage_states is
                WHEN t0 => 
                    step_length := tsw/2.0-abs(phi)/2.0-abs(phi)/2.0;
                    next_st_dab_voltage_states := t1;
                WHEN t1 => 
                    step_length := abs(phi);
                    next_st_dab_voltage_states := t2;
                WHEN t2 => 
                    step_length := tsw/2.0-abs(phi)/2.0-abs(phi)/2.0;
                    next_st_dab_voltage_states := t3;
                WHEN t3 =>
                    step_length := abs(phi);
                    next_st_dab_voltage_states := t0;
            end CASE;

            return step_length;
        end next_timestep;

        ------------
        impure function deriv(t : real; states : real_vector) return real_vector is
            alias uout is states(1);
            variable i_out         : real := 0.0;
            variable i_cm          : real := 0.0;
            variable i_hb_current  : real := 0.0;
            variable i_out_current : real := 0.0;

            -- define sign function to return only {-1.0, 1.0} to make 0 phase work correctly
            function sign(a : real) return real is
                variable retval : real := 1.0;
            begin
                if a < 0.0 then
                    retval := -1.0;
                else
                    retval := 1.0;
                end if;
                return retval;

            end function;

            variable out_parallel_gain : real := output_capacitor/(output_capacitor+half_bridge_capacitor);
            variable hb_parallel_gain  : real := half_bridge_capacitor/(output_capacitor+half_bridge_capacitor);

            variable retval : state_variables'subtype;
            variable un : real;

            function calculate_un (u : real_vector; l : real_vector) return real is
            begin
                return (u(0) * l(1)*l(2) + u(1)*l(0)*l(2) + u(2)*l(0)*l(1)) 
                        / (l(0)*l(1) + l(0)*l(2) + l(1)*l(2));
            end function;

            variable upri : real;
            variable usec : real;
            
            -- variable ipri : real;
            -- variable isec : real;

        begin

            CASE st_dab_voltage_states is
                WHEN t0 => 
                    upri := sign(phi) * uin;
                    usec := sign(phi) * uout;

                    i_out        := -states(isec) * out_parallel_gain;
                    i_hb_current := -states(isec) * hb_parallel_gain;

                    i_n := calculate_un((-states(isec), 0.0, -iload),(half_bridge_capacitor, half_bridge_capacitor, output_capacitor));

                WHEN t1 => 
                    upri := sign(phi)  * uin;
                    usec := -sign(phi) * uout;

                    i_out        := states(isec) * out_parallel_gain;
                    i_hb_current := states(isec) * hb_parallel_gain;

                    i_n := calculate_un((0.0, states(isec), -iload),(half_bridge_capacitor, half_bridge_capacitor, output_capacitor));

                WHEN t2 => 
                    upri := -sign(phi) * uin;
                    usec := -sign(phi) * uout;

                    i_out        := states(isec) * out_parallel_gain;
                    i_hb_current := states(isec) * hb_parallel_gain;

                    i_n := calculate_un((0.0, states(isec), -iload),(half_bridge_capacitor, half_bridge_capacitor, output_capacitor));

                WHEN t3 => 
                    upri := -sign(phi) * uin;
                    usec := sign(phi)  * uout;

                    i_out        := -states(isec) * out_parallel_gain;
                    i_hb_current := -states(isec) * hb_parallel_gain;

                    i_n := calculate_un((-states(isec), 0.0, -iload),(half_bridge_capacitor, half_bridge_capacitor, output_capacitor));

            end CASE;

            un := calculate_un((upri- states(ipri) * 0.1, usec- states(isec) * 0.1, 0.0),(lpri, lsec, lm));


            retval := (
                0     => ((upri - un) - states(ipri) * 0.1)/lpri
                -- ,1    => (i_n)/output_capacitor
                ,1    => (i_out/2.0    + iload * out_parallel_gain/2.0)/output_capacitor
                ,2    => (i_hb_current + iload * hb_parallel_gain) / half_bridge_capacitor
                ,3    => (i_hb_current + iload * hb_parallel_gain) / half_bridge_capacitor
                ,4    => 0.0
                ,5    => 0.0
                ,isec => (un - usec - states(isec) * 0.1) / lsec
                ,im   => (un)/lm
            );

            return retval;

        end deriv;
        ------------

        procedure rk is new generic_rk4 generic map(deriv);

        file file_handler : text open write_mode is "dab_simulation_tb.dat";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, 
                ("time"
                ,"T_u0"
                ,"B_i0"
                ,"T_vc"
                ,"B_ph"
                ,"B_mg"
                ));

                request_pi_control(pi_controller, to_fixed(200.0 - state_variables(1),12));
            end if;

            create_multiplier(multiplier);
            create_pi_controller(pi_controller
                 , multiplier
                 , to_fixed(0.25   , mpy_signed'length , 14)
                 , to_fixed(0.025 , mpy_signed'length , 14));

            if pi_control_is_ready(pi_controller) then
                phase := to_real(get_pi_control_output(pi_controller), 15);
                request_pi_control(pi_controller
                    , pi_control_input => to_fixed(200.0 - state_variables(1) , 12));
            end if;

            if simulation_counter > 0 then

                write_to(file_handler,
                        (realtime
                         , state_variables(uout)
                         , state_variables(ipri)
                         , state_variables(sec_lower_cap) + state_variables(sec_upper_cap) - 200.0
                         , state_variables(isec) - state_variables(ipri)
                         , i_n
                    ));

                rk(realtime , state_variables , timestep);
                realtime <= realtime + timestep;
                timestep := next_timestep;

                if (realtime > 3.0e-3) then iload := -2.0 ; end if ;
                -- if (realtime > 4.5e-3) then iload := 1.0  ; end if ;
                -- if (realtime > 5.5e-3) then iload := -5.0 ; end if ;
                if (realtime > 7.5e-3) then iload := 2.0  ; end if ;
                -- if (realtime > 9.5e-3) then iload := -3.0 ; end if ;
                iload := iload/2.0;

                -- if realtime > 5.0e-3 then
                --     load_resistor := -400.0;
                -- end if;
                --
                -- if realtime > 10.0e-3 then
                --     load_resistor := 400.0;
                -- end if;
                --
                -- if realtime > 15.25e-3 then
                --     tsw := 10.0e-6;
                -- end if;

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
