LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;

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
    constant stoptime : real := 20.0e-3;

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
        variable carrier : real := 0.0;
        variable voltage_over_dab_inductor : real := 0.0;
        type dab_voltage_states is (t0, t1, t2, t3);
        variable st_dab_voltage_states : dab_voltage_states := t0;
        variable next_st_dab_voltage_states : dab_voltage_states := t0;

        variable tsw     : real := 10.0e-6;
        variable phase   : real := 0.4;
        variable phi     : real := tsw/4.0*phase;
        variable phi_old : real := tsw/4.0*phase;
        variable phi_new : real := tsw/4.0*phase;

        variable dab_inductor     : real := 75.0e-6;
        variable output_capacitor : real := 100.0e-6;

        variable uin : real := 200.0;
        variable state_variables : real_vector(0 to 1) := (-2.0, 200.0);

        variable sw1_current : real := 0.0;
        variable load_resistor : real := 2000.0;

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
            variable i_out : real := 0.0;

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

        begin

            CASE st_dab_voltage_states is
                WHEN t0 => 
                    voltage_over_dab_inductor := sign(phi) * (uin-uout);
                    i_out := -states(0);
                WHEN t1 => 
                    voltage_over_dab_inductor := sign(phi) * (uin+uout); 
                    i_out := states(0);
                WHEN t2 => 
                    voltage_over_dab_inductor := -sign(phi) * (uin-uout);
                    i_out := states(0);
                WHEN t3 => 
                    voltage_over_dab_inductor := -sign(phi) * (uin+uout);
                    i_out := -states(0);
            end CASE;

            carrier := (carrier + timestep) mod 0.001;

            return (
                (voltage_over_dab_inductor - states(0) * 0.1)/dab_inductor 
                ,(i_out/2.0 - states(1)/load_resistor)/output_capacitor
            );

        end deriv;
        ------------

        procedure rk is new generic_rk4 generic map(deriv);

        file file_handler : text open write_mode is "dab_simulation_tb.dat";

        variable integrator : real := 0.0;
        variable pi_out : real := 0.0;
        variable err : real := 0.0;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, 
                ("time"
                ,"T_u0"
                ,"B_i0"
                ,"B_ph"
                ,"B_st"
                ));
            end if;

            if simulation_counter > 0 then

                write_to(file_handler,
                        (realtime
                        ,state_variables(0)
                        ,state_variables(1)
                        ,phase
                        ,timestep
                    ));

                

                rk(realtime , state_variables , timestep);
                realtime <= realtime + timestep;
                timestep := next_timestep;

                err := 202.0 - state_variables(1);
                phase := 0.5 * err + integrator;
                integrator := 0.025 * err + integrator;
                if phase > 1.0 then
                    phase := 1.0;
                    integrator := 1.0 - 0.5 *err;
                end if;

                if phase < -1.0 then
                    phase := -1.0;
                    integrator := -1.0 - 0.5 *err;
                end if;

                if realtime > 5.0e-3 then
                    load_resistor := -400.0;
                end if;

                if realtime > 10.0e-3 then
                    load_resistor := 400.0;
                end if;

                if realtime > 15.25e-3 then
                    tsw := 18.0e-6;
                end if;

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
