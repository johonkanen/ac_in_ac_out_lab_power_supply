LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package grid_inverter_model_pkg is

    constant c1    : natural := 0;
    constant l1    : natural := 1;
    constant c2    : natural := 2;
    constant l2    : natural := 3;
    constant c3    : natural := 4;
    constant lpri  : natural := 5;
    constant cdc   : natural := 6;
    constant timestep : real := 2.0e-6;

    function deriv_grid_inverter(states : real_vector; modulation_index : real ; load_current : real; grid_voltage : real) return real_vector;

end package grid_inverter_model_pkg;

package body grid_inverter_model_pkg is

        -----------------------------
        function bridge_voltage(
            dc_link_voltage : real
            ;input_voltage : real
            ;inductor_current : real
            ;modulation_index : real := 1.0
        ) return real is
            variable retval : real := 0.0;
        begin

            if modulation_index >= 1.0
            then
                if (modulation_index * dc_link_voltage < input_voltage) or (inductor_current > 0.0)
                then
                    retval := abs(input_voltage) - dc_link_voltage * modulation_index;
                end if;
            else
                retval := input_voltage - dc_link_voltage * modulation_index;
            end if;

            return retval;
        end bridge_voltage;
        -----------------------------

        constant c1_val          : real := 2.0e-6;
        constant c2_val          : real := 7.0e-6;
        constant rc1             : real := 10.0e-3;
        constant rc2             : real := 10.0e-3;

        constant l1_val          : real := 2.2e-6;
        constant l2_val          : real := 2.2e-6;
        constant Lpri_val        : real := 1.0e-3;
        constant lgrid           : real := 10.0e-6;
        constant dc_link_cap_val : real := 1500.0e-6;

            function deriv_grid_inverter(states : real_vector; modulation_index : real ; load_current : real; grid_voltage : real) return real_vector is
                variable l1_voltage      : real := 0.0;
                variable c1_current      : real := 0.0;
                variable l2_voltage      : real := 0.0;
                variable c2_current      : real := 0.0;
                variable lpri_voltage    : real := 0.0;
                variable dc_link_current : real := 0.0;
                variable bridge_current  : real := 0.0;

                variable retval : states'subtype := (others => 0.0);

            begin
                l1_voltage := grid_voltage - states(c1) - rc1*(states(l1) - states(l2));
                c1_current := states(l1) - states(l2);
                l2_voltage := states(c1) - states(c2) - rc1*(states(l1) - states(l2)) - rc2*(states(l2) - states(lpri));
                c2_current := states(l2) - states(lpri);

                lpri_voltage := bridge_voltage(
                    dc_link_voltage   => states(cdc)
                    ,input_voltage    => states(c2)
                    ,inductor_current => states(lpri)
                    ,modulation_index => modulation_index
                );

                dc_link_current := (modulation_index * states(lpri) - load_current);

                retval(l1)   := l1_voltage      / l1_val;
                retval(c1)   := c1_current      / c1_val;
                retval(l2)   := l2_voltage      / l2_val;
                retval(c2)   := c2_current      / c2_val;
                retval(lpri) := lpri_voltage    / Lpri_val;
                retval(cdc)  := dc_link_current / dc_link_cap_val;

                return retval;
            end deriv_grid_inverter;

end package body grid_inverter_model_pkg;

----
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;
    use work.grid_inverter_model_pkg.all;

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
    constant stoptime : real := 300.0e-3;

    signal control_is_ready : boolean := false;
    signal request_control : boolean := false;
    signal modulation_index : real := 0.0;

    signal v_int   : real := 0.0;
    signal i_int   : real := 0.0;
    signal pi_out  : real := 0.0;
    signal vpi_out : real := 0.0;

    signal lpri_meas : real := 0.0;
    signal cap_voltage_meas : real := 0.0;
    signal dc_link_meas : real := 0.0;


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


        constant int  : natural := 8;
        constant vint : natural := 9;

        -- c1, l1, c2, l2, c3, lpri, cdc
        variable grid_inverter_states : real_vector(0 to 9) := (cdc => 400.0, others => 0.0);

        impure function deriv_lcr (t : real ; states : real_vector) return real_vector is

            variable retval : grid_inverter_states'subtype := (others => 0.0);
            variable grid_voltage : real := 0.0;
            variable load_current : real := 10.0;



        begin
            grid_voltage := sin(t*50.0*math_pi*2.0 mod (2.0*math_pi)) * 325.0;


            load_current := 2.0;

            if t > 150.0e-3 then load_current := 10.0; end if;

            -- if t > 70.0e-3 then vref := 410.0; end if;



            return deriv_grid_inverter(states, modulation_index, load_current, grid_voltage);

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
                -- ,"T_u1"
                -- ,"T_u2"
                -- ,"T_u2"
                -- ,"T_u3"
                ,"B_i0"
                -- ,"B_i1"
                -- ,"B_i2"
                -- ,"B_i3"
                ));

            end if;

            request_control <= false;
            if control_is_ready or simulation_counter = 0
            then
                write_to(file_handler
                        ,(realtime
                        -- ,grid_inverter_states(c1) 
                        -- ,grid_inverter_states(c2) 
                        ,grid_inverter_states(cdc) 
                        ,grid_inverter_states(lpri) 
                        -- ,(grid_voltage - grid_inverter_states(c1)) / rc1
                    ));

                rk(realtime, grid_inverter_states, timestep);
                realtime <= realtime + timestep;

                request_control  <= true;
                lpri_meas        <= grid_inverter_states(lpri);
                cap_voltage_meas <= grid_inverter_states(c2);
                dc_link_meas     <= grid_inverter_states(cdc);
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------

    control : process(simulator_clock)
        variable verr  : real := 0.0;
        variable i_err : real := 0.0;
        variable vref  : real := 400.0;
    begin
        if rising_edge(simulator_clock)
        then
            control_is_ready <= false;
            if request_control
            then
                verr     := vref - dc_link_meas;
                vpi_out <= verr * 0.2 + v_int;
                v_int   <= verr * 50.0 * timestep + v_int;

                i_err  := cap_voltage_meas/325.0 * vpi_out - lpri_meas;
                pi_out           <= i_err * 250.0 + i_int;
                i_int            <= i_err * 100000.0* timestep+ i_int;
                modulation_index <= -(pi_out + cap_voltage_meas) / dc_link_meas;
                control_is_ready <= true;
            end if;
        end if;
    end process;
------------------------------------------------------------------------
end vunit_simulation;
