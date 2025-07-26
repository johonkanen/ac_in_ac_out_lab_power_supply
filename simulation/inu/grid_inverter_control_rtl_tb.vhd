LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.ram_connector_pkg.all;

package grid_inverter_microprogram_pkg is

    constant instruction_length : natural := 32;
    constant word_length  : natural := 35;
    constant integer_bits : natural := 11;
    constant used_radix   : natural := 20;
    
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
    -- 
    constant scaled_udc :     natural := 10;
    constant scaled_uin :     natural := 11;
    constant scaled_current : natural := 12;
    constant scaled_ubridge : natural := 13;

    constant ad_udc_gain       : natural := 14;
    constant ad_udc_offset     : natural := 15;
    constant ad_uin_gain       : natural := 16;
    constant ad_uin_offset     : natural := 17;
    constant ad_current_gain   : natural := 18;
    constant ad_current_offset : natural := 19;
    constant ad_ubridge_gain   : natural := 20;
    constant ad_ubridge_offset : natural := 21;

    constant uerror_x_kp : natural := 22;
    constant uerror_x_ki : natural := 23;
    constant iref_max    : natural := 24;
    constant iref_min    : natural := 25;

    constant udckp   : natural := 26;
    constant udcki   : natural := 27;
    constant upi_out : natural := 28;

    constant idckp   : natural := 29;
    constant idcki   : natural := 30;
    constant ipi_out : natural := 31;

    constant ierror_x_kp : natural := 32;
    constant ierror_x_ki : natural := 33;
    constant uref_max    : natural := 34;
    constant uref_min    : natural := 35;

    constant u_integral  : natural := 37;
    constant i_integral  : natural := 38;
    constant uin_scale   : natural := 39;
    constant iref_scale  : natural := 40;
    constant current_ref : natural := 41;
    constant modulation_index_addr : natural := 42;

    constant ipi_out_high  : natural := 43;
    constant ipi_out_low   : natural := 44;

    constant duty_max : natural := 45;
    constant duty_min : natural := 46;

    constant upi_out_max : natural := 47;
    constant upi_out_min : natural := 48;

    ---------- external data
    constant ad_udc_meas     : natural := 120;
    constant ad_uin_meas     : natural := 122;
    constant ad_current_meas : natural := 123;
    constant ad_ubridge_meas : natural := 124;
    constant inverse_udc : natural := 125;

    constant udc_ref : natural := 126;

    constant sampletime : real := 20.0e-6;

    constant program_data : work.dual_port_ram_pkg.ram_array(0 to ref_subtype.address_high)(ref_subtype.data'range) := (
           0 => to_fixed(0.0) -- currently zero address is bugged
        ,  1 => to_fixed(1.0)
        ,  2 => to_fixed(2.0)
        ,  3 => to_fixed(-3.0)
        ,  4 => to_fixed(0.0)

        -- , duty             => to_fixed(0.5)
        -- , inductor_current => to_fixed(0.0)
        -- , cap_voltage      => to_fixed(0.0)
        -- , ind_res          => to_fixed(0.9)
        -- , load             => to_fixed(0.0)
        -- , current_gain     => to_fixed(sampletime*1.0/2.0e-6)
        -- , voltage_gain     => to_fixed(sampletime*1.0/3.0e-6)
        -- , input_voltage    => to_fixed(10.0)
        -- , inductor_voltage => to_fixed(0.0)

        -- get correct parameters for conversions
        ,ad_udc_gain       => to_fixed(1.0)
        ,ad_udc_offset     => to_fixed(0.0)
        ,ad_uin_gain       => to_fixed(1.0)
        ,ad_uin_offset     => to_fixed(0.0)
        ,ad_current_gain   => to_fixed(1.0)
        ,ad_current_offset => to_fixed(0.0)
        ,ad_ubridge_gain   => to_fixed(1.0)
        ,ad_ubridge_offset => to_fixed(0.0)
        ,uin_scale         => to_fixed(1.0/325.0)

        , udckp => to_fixed(0.2)
        , udcki => to_fixed(50.0 * sampletime)
        , idckp => to_fixed(40.0)
        , idcki => to_fixed(280000.0 * sampletime)

        , others => (others => '0')
    );

    constant test_program : work.dual_port_ram_pkg.ram_array(0 to instr_ref_subtype.address_high)(instr_ref_subtype.data'range) := (
        -- measurement scaling
        0   => op(mpy_add , scaled_udc     , ad_udc_gain     , ad_udc_meas     , ad_udc_offset)
        , 1 => op(mpy_add , scaled_uin     , ad_uin_gain     , ad_uin_meas     , ad_uin_offset)
        , 2 => op(mpy_add , scaled_current , ad_current_gain , ad_current_meas , ad_current_offset)
        , 3 => op(mpy_add , scaled_ubridge , ad_ubridge_gain , ad_ubridge_meas , ad_ubridge_offset)

        -- voltage control
        , 7 => op(a_sub_b_mpy_c , uerror_x_kp , udc_ref    , scaled_udc , udckp)
        , 8 => op(a_sub_b_mpy_c , uerror_x_ki , udc_ref    , scaled_udc , udcki)
        , 9 => op(mpy_add       , iref_scale  , scaled_uin , uin_scale  , 4)

        -- max_voltage = duty_max * dc_link - c2
        -- min_voltage = duty_min * dc_link - c2
        , 10 => op(mpy_sub , ipi_out_high , duty_max , scaled_udc , scaled_ubridge)
        , 11 => op(mpy_sub , ipi_out_low  , duty_min , scaled_udc , scaled_ubridge)

        , 13 => op(acc, u_integral)
        , 14 => op(acc, uerror_x_kp)
        -- , 15 => op(check_and_saturate_acc, imax, )

        , 17 => op(get_acc_and_zero, upi_out, 4)
        , 18 => op(mpy_add, u_integral, uerror_x_ki, 1, u_integral)

        -- calculate saturation limits

        -- current control
        , 23 => op(mpy_add , current_ref , upi_out , iref_scale, 4)
        , 30 => op(a_sub_b_mpy_c, ierror_x_kp , current_ref, scaled_current, idckp)
        , 31 => op(a_sub_b_mpy_c, ierror_x_ki , current_ref, scaled_current, idcki)

        , 36 => op(acc, scaled_ubridge)
        , 37 => op(acc, i_integral)
        , 38 => op(get_acc_and_zero, ipi_out, ierror_x_kp)
        , 39 => op(mpy_add, i_integral, ierror_x_ki, 1, i_integral)

        -- modulator
        , 44 => op(neg_mpy_add, modulation_index_addr, ipi_out, inverse_udc, 4)

        , 48 => op(program_end)
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
    constant stoptime : real := 250.0e-3;

    signal control_is_ready : boolean := false;
    signal request_control : boolean := false;
    signal modulation_index : real := 0.0;

    signal v_int   : real := 0.0;
    signal i_int   : real := 0.0;
    signal pi_out  : real := 0.0;
    signal vpi_out : real := 0.0;

    signal lpri_meas        : real := 0.0;
    signal cap_voltage_meas : real := 0.0;
    signal dc_link_meas     : real := 400.0;
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

    signal uproc_udc_voltage : real := 400.0;
    signal uproc_uc_voltage : real := 0.0;
    signal uproc_current : real := 0.0;
    signal uproc_upi_out : real := 0.0;
    signal uproc_ipi_out : real := 0.0;

    signal control_counter : natural := 9;

    use work.reciproc_pkg.all;
    use work.real_to_fixed_pkg.all;
    constant init_reciproc : reciprocal_record := create_reciproc_typeref(word_length);
    signal reciproc : init_reciproc'subtype := init_reciproc;
    signal inv_test : real := 0.0;

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
                ,"T_u1"
                ,"T_u2"
                ,"T_u3"

                ,"B_i0"
                ,"B_i1"
                ,"B_i2"
                -- ,"B_i3"
                ));

            end if;

            request_control <= false;
            if control_is_ready or (control_counter < 10) or simulation_counter = 0
            then
                write_to(file_handler
                        ,(realtime
                        -- ,grid_inverter_states(c1) 
                        -- ,grid_inverter_states(c2) 
                        ,grid_inverter_states(cdc) 
                        ,uproc_udc_voltage 
                        ,uproc_uc_voltage 
                        ,inv_test

                        ,uproc_current 
                        ,uproc_ipi_out 
                        -- ,(grid_voltage - grid_inverter_states(c1)) / rc1
                    ));

                rk(realtime, grid_inverter_states, timestep);
                realtime <= realtime + timestep;

                lpri_meas        <= grid_inverter_states(lpri);
                cap_voltage_meas <= grid_inverter_states(c2);
                dc_link_meas     <= grid_inverter_states(cdc);

                control_counter <= control_counter + 1;
                if control_counter = 9 
                then
                    request_control <= true;
                end if;

            end if;
            if control_is_ready
            then
                control_counter <= 0;
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------

    control : process(simulator_clock)
        variable verr  : real := 0.0;
        variable i_err : real := 0.0;
        variable vref  : real := 400.0;

        function convert(data_in : std_logic_vector) return real is
        begin
            return work.real_to_fixed_pkg.to_real(signed(data_in), used_radix);
        end convert;

        procedure connect_ram_write_to_address is new generic_connect_ram_write_to_address generic map(return_type => real, conv => convert);

    begin
        if rising_edge(simulator_clock)
        then

            create_reciproc(reciproc, max_shift => 8, output_int_length => (word_length - used_radix)*2-3);

            init_ram_connector(ram_connector);
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , ad_udc_meas     , to_fixed(dc_link_meas));
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , ad_uin_meas     , to_fixed(cap_voltage_meas));
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , ad_ubridge_meas , to_fixed(cap_voltage_meas));
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , ad_current_meas , to_fixed(lpri_meas));
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , udc_ref         , to_fixed(vref));
            connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , inverse_udc     , to_fixed(1.0/dc_link_meas));
            -- connect_data_to_ram_bus(ram_connector , mc_read_in , mc_read_out , inverse_udc     , std_logic_vector(get_result(reciproc)));

            connect_ram_write_to_address(mc_output , scaled_uin            , uproc_udc_voltage);
            connect_ram_write_to_address(mc_output , scaled_ubridge        , uproc_uc_voltage);
            connect_ram_write_to_address(mc_output , scaled_current        , uproc_current);
            connect_ram_write_to_address(mc_output , upi_out               , uproc_upi_out);
            -- connect_ram_write_to_address(mc_output , ipi_out               , uproc_ipi_out);
            connect_ram_write_to_address(mc_output , current_ref           , uproc_ipi_out);
            connect_ram_write_to_address(mc_output , modulation_index_addr , modulation_index);
            connect_ram_write_to_address(mc_output , cap_voltage           , simvoltage);

            init_mproc(mproc_in);
            if request_control
            then
                request_inv(reciproc, signed(to_fixed(dc_link_meas)), iterations => 1);
                calculate(mproc_in, 0);
            end if;

            if is_ready(reciproc)
            then
                inv_test <= 1.0/to_real(get_result(reciproc), used_radix);
            end if;

            control_is_ready <= is_ready(mproc_out);

        end if;
    end process;
-------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_processor
    generic map(g_data_bit_width => word_length,g_used_radix => used_radix, g_program => test_program, g_data => program_data)
    port map(simulator_clock, mproc_in, mproc_out, mc_read_in, mc_read_out, mc_output);
-------------------------------------------------------------------------
------------------------------------------------------------------------
end vunit_simulation;
