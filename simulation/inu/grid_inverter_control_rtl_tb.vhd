LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.ram_connector_pkg.all;

package grid_inverter_microprogram_pkg is

    constant instruction_length : natural := 32;
    constant word_length : natural := 40;
    constant used_radix : natural := 29;
    
    use work.real_to_fixed_pkg.all;
    function to_fixed is new generic_to_fixed 
    generic map(word_length => word_length, used_radix => used_radix);

    use work.microinstruction_pkg.all;

    use work.multi_port_ram_pkg.all;
    constant ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 3, datawidth => word_length, addresswidth => 10);

    constant instr_ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 1, datawidth => 32, addresswidth => 10);


    constant readports    : natural := 3;
    constant addresswidth : natural := 10;
    constant datawidth    : natural := word_length;

    constant ram_connector_ref : ram_connector_record := (
            read_in => (
                0 to readports - 1 => (
                    address        => (0 to addresswidth - 1 => '0'),
                    read_requested => '0'
                )
            )

            ,read_out => (
                0 to readports - 1 => (
                    data          => (datawidth - 1 downto 0 => '0'),
                    data_is_ready => '0'
                )
            ));

    constant y    : natural := 50;
    constant u    : natural := 60;
    constant uext : natural := 120;
    constant g    : natural := 70;

    constant load             : natural := 121;
    constant duty             : natural := 122;
    constant input_voltage    : natural := 123;

    constant inductor_current : natural := 22;
    constant cap_voltage      : natural := 23;
    constant ind_res          : natural := 24;
    constant current_gain     : natural := 26;
    constant voltage_gain     : natural := 27;
    constant inductor_voltage : natural := 29;
    constant rxi              : natural := 30;
    constant cap_current      : natural := 31;

    constant sampletime : real := 1.0e-6;

    constant program_data : work.dual_port_ram_pkg.ram_array(0 to ref_subtype.address_high)(ref_subtype.data'range) := (
           0 => to_fixed(0.0)
        ,  1 => to_fixed(1.0)
        ,  2 => to_fixed(2.0)
        ,  3 => to_fixed(-3.0)

        , duty             => to_fixed(0.5)
        , inductor_current => to_fixed(0.0)
        , cap_voltage      => to_fixed(0.0)
        , ind_res          => to_fixed(0.9)
        , load             => to_fixed(0.0)
        , current_gain     => to_fixed(sampletime*1.0/2.0e-6)
        , voltage_gain     => to_fixed(sampletime*1.0/3.0e-6)
        , input_voltage    => to_fixed(10.0)
        , inductor_voltage => to_fixed(0.0)

        , others => (others => '0')
    );

    constant test_program : work.dual_port_ram_pkg.ram_array(0 to instr_ref_subtype.address_high)(instr_ref_subtype.data'range) := (
        6    => sub(5, 1, 1)
        , 7  => add(6, 1, 1)
        , 8  => mpy(7, 2, 2)
        , 9  => op(mpy_add,8, 2, 2, 1)
        , 10  => op(mpy_sub,9, 2, 2, 1)
        , 13 => op(program_end)

        -- lc filter
        , 129 => op(neg_mpy_add , inductor_voltage , duty             , cap_voltage      , input_voltage)
        , 130 => op(mpy_sub     , cap_current      , duty             , inductor_current , load)
        , 136 => op(neg_mpy_add , inductor_voltage , ind_res          , inductor_current , inductor_voltage)
        , 137 => op(mpy_add     , cap_voltage      , cap_current      , voltage_gain     , cap_voltage)
        , 143 => op(mpy_add     , inductor_current , inductor_voltage , current_gain     , inductor_current)
        , 144 => op(program_end)

        , others => op(nop));

end package grid_inverter_microprogram_pkg;

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
    use work.grid_inverter_microprogram_pkg.all;

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
    constant stoptime : real := 60.0e-3;

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
------------------------------------------------------------------------
    signal ext_input : std_logic_vector(word_length-1 downto 0) := to_fixed(-22.351);
    signal mc_read_in  : ref_subtype.ram_read_in'subtype;
    signal mc_read_out : ref_subtype.ram_read_out'subtype;
    signal mc_output   : ref_subtype.ram_write_in'subtype;

    signal current : real := 0.0;
    signal voltage : real := 0.0;

    signal lc_load : std_logic_vector(word_length-1 downto 0)          := to_fixed(1.0);
    signal lc_duty : std_logic_vector(word_length-1 downto 0)          := to_fixed(0.5);
    signal lc_input_voltage : std_logic_vector(word_length-1 downto 0) := to_fixed(10.0);

    use work.microprogram_processor_pkg.all;

    signal mproc_in  : microprogram_processor_in_record;
    signal mproc_out : microprogram_processor_out_record;

    signal start_counter : natural range 0 to 127 := 0;

    signal simcurrent : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal simvoltage : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);

    use work.ram_connector_pkg.all;
    signal ram_connector : ram_connector_ref'subtype;



------------------------------------------------------------------------
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


            init_ram_connector(ram_connector);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 120, ext_input);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 121, lc_load);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 122, lc_duty);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 123, lc_input_voltage);
            connect_ram_write_to_address(mc_output , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_output , cap_voltage      , simvoltage);

            init_mproc(mproc_in);
            if request_control
            then
                verr     := vref - dc_link_meas;
                vpi_out <= verr * 0.2 + v_int;
                v_int   <= verr * 50.0 * timestep + v_int;

                i_err  := cap_voltage_meas/325.0 * vpi_out - lpri_meas;
                pi_out           <= i_err * 250.0 + i_int;
                i_int            <= i_err * 100000.0* timestep+ i_int;
                modulation_index <= -(pi_out + cap_voltage_meas) / dc_link_meas;
                calculate(mproc_in, 129);
                start_counter <= 0;
            end if;

            if start_counter < 81 then
                start_counter <= start_counter + 1;
            end if;

            control_is_ready <= false;
            if start_counter = 80
            then
                control_is_ready <= true;
            end if;

        end if;
    end process;
-------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_processor
    generic map(g_data_bit_width => word_length,g_used_radix => used_radix, g_program => test_program, g_data => program_data)
    port map(simulator_clock, mproc_in, mproc_out, mc_read_in, mc_read_out, mc_output);
-------------------------------------------------------------------------
------------------------------------------------------------------------
end vunit_simulation;
