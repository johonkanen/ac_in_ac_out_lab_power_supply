LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;
    use work.lcr_models_pkg.all;

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
    constant stoptime : real := 10.0e-3;

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
        variable st_dab_voltage_states : dab_voltage_states := t1;

        variable phi     : real := 500.0e-9;
        variable phi_old : real := 500.0e-9;
        variable phi_new : real := 500.0e-9;
        variable tsw     : real := 10.0e-6;

        impure function next_timestep return real is
            variable step_length : real := 1.0;
        begin
            CASE st_dab_voltage_states is
                WHEN t0 => 
                    step_length := tsw/2.0-phi_old/2.0-phi_new/2.0;
                    st_dab_voltage_states := t1;
                WHEN t1 => 
                    step_length := phi;
                    st_dab_voltage_states := t2;
                WHEN t2 => 
                    step_length := tsw/2.0-phi_old/2.0-phi_new/2.0;
                    st_dab_voltage_states := t3;
                WHEN t3 =>
                    step_length := phi;
                    st_dab_voltage_states := t0;
            end CASE;

            return step_length;
        end next_timestep;

        ------------
        impure function deriv(t : real; states : real_vector) return real_vector is
            variable uin : real := 200.0;
            variable uout : real := 200.0;
        begin

            CASE st_dab_voltage_states is
                WHEN t3 => voltage_over_dab_inductor := uin-uout;
                WHEN t0 => voltage_over_dab_inductor := uin+uout; 
                WHEN t1 => voltage_over_dab_inductor := -(uin-uout);
                WHEN t2 => voltage_over_dab_inductor := -(uin+uout);
            end CASE;

            carrier := (carrier + timestep) mod 0.001;

            return (voltage_over_dab_inductor/8.0e-6, -0.1);

        end deriv;
        ------------

        procedure rk4 is new generic_rk4 generic map(deriv);
        variable state_variables : real_vector(0 to 1) := (1.0, 0.0);

        file file_handler : text open write_mode is "dab_simulation_tb.dat";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, 
                ("time"
                ,"T_u0"
                ,"B_i0"
                ,"B_st"
                ));
            end if;

            if simulation_counter > 0 then

                write_to(file_handler,
                        (realtime
                        ,state_variables(0)
                        ,carrier
                        ,timestep
                    ));

                rk4(realtime , state_variables , timestep);
                realtime <= realtime + timestep;
                timestep := next_timestep;

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
