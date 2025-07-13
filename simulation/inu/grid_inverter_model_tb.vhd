LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;

entity grid_inverter_model_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of grid_inverter_model_tb is

    constant clock_period : time := 1 ns;
    
    signal simulator_clock    : std_logic := '0';
    signal simulation_counter : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal realtime : real := 0.0;
    constant timestep : real := 1.0e-7;
    constant stoptime : real := 100.0e-3;
    constant c1   : natural := 0;
    constant l1   : natural := 1;
    constant c2   : natural := 2;
    constant l2   : natural := 3;
    constant c3   : natural := 4;
    constant lpri : natural := 5;
    constant cdc  : natural := 6;

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

        variable grid_voltage : real := 0.0;

        constant c1_val          : real := 7.0e-6;
        constant c2_val          : real := 7.0e-6;
        constant rc1             : real := 10.0e-3;
        constant l1_val          : real := 2.2e-6;
        constant l2_val          : real := 2.2e-6;
        constant dc_link_cap_val : real := 1500.0e-6;
        variable load_current    : real := 1.0;

        -- c1, l1, c2, l2, c3, lpri, cdc
        variable grid_inverter_states : real_vector(0 to 6) := ( cdc => 400.0, others => 0.0);

        impure function deriv_lcr (t : real ; states : real_vector) return real_vector is
            variable retval : grid_inverter_states'subtype := (others => 0.0);
            variable voltage_over_bridge : real := 0.0;
            variable bridge_current : real := 0.0;
        begin
            grid_voltage := sin(t*50.0*math_pi*2.0 mod (2.0*math_pi)) * 230.0;

            -- voltage_over_bridge := states(cdc) - (abs(states(c1)));
            -- bridge_current := 0.0;
            -- if voltage_over_bridge > 0.0
            -- then
            --     bridge_current := voltage_over_bridge * 500.0;
            -- end if;

            retval(c1) := (grid_voltage - states(c1)) / rc1 / c1_val;

            retval(cdc) := (bridge_current - load_current*0.0) / dc_link_cap_val;
            -- retval(l1) := (states(c1) - states(c2) * states(l1) * 1.0e-3) / l1_val;
            -- retval(c2) := (states(l1)) / c2_val;

            return retval;

        end function;

        procedure rk is new generic_rk5 generic map(deriv_lcr);

        file file_handler : text open write_mode is "inu_model_tb.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler
                , ("time"
                ,"T_u0"
                ,"T_u1"
                -- ,"T_u2"
                -- ,"T_u3"
                -- ,"B_i0"
                -- ,"B_i1"
                -- ,"B_i2"
                ,"B_i3"
                ));
            end if;

            -- if simulation_counter > 0 then

                rk(realtime, grid_inverter_states, timestep);

                realtime <= realtime + timestep;
                write_to(file_handler
                        ,(realtime
                        ,grid_inverter_states(c1) 
                        ,grid_inverter_states(cdc) 
                        ,(grid_voltage - grid_inverter_states(c1)) / rc1
                    ));

            -- end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
