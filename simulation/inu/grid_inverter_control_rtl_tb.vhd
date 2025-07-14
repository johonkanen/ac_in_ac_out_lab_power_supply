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

entity grid_inverter_control_rtl_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of grid_inverter_control_rtl_tb is

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

    signal lpri_meas        : real := 0.0;
    signal cap_voltage_meas : real := 0.0;
    signal dc_link_meas     : real := 0.0;


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

            return deriv_grid_inverter(states, modulation_index, load_current, grid_voltage);

        end function;

        procedure rk is new generic_rk5 generic map(deriv_lcr);

        file file_handler : text open write_mode is "grid_inverter_control_rtl_tb.dat";

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
