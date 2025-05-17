---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity titanium_top is
    port (
        main_clock : in std_logic;
        pll_locked   : in std_logic;

        uart_rx      : in std_logic;
        uart_tx      : out std_logic;

        grid_inu_leg1_hi  : out std_logic;
        grid_inu_leg1_low : out std_logic;
        grid_inu_leg2_hi  : out std_logic;
        grid_inu_leg2_low : out std_logic;

        dab_primary_hi    : out std_logic;
        dab_primary_low   : out std_logic;
        dab_secondary_hi  : out std_logic;
        dab_secondary_low : out std_logic;

        output_inu_leg1_hi  : out std_logic;
        output_inu_leg1_low : out std_logic;
        output_inu_leg2_hi  : out std_logic;
        output_inu_leg2_low : out std_logic;

        primary_bypass_relay   : out std_logic;
        secondary_bypass_relay : out std_logic;

        gate_power1_pwm : out std_logic;
        gate_power2_pwm : out std_logic;
        gate_power3_pwm : out std_logic;
        gate_power4_pwm : out std_logic;
        gate_power5_pwm : out std_logic;
        gate_power6_pwm : out std_logic;

        grid_inu_sdm_clock   : out std_logic;
        output_inu_sdm_clock : out std_logic;
        dab_sdm_clock        : out std_logic;

        ad_mux1_io           : out std_logic_vector(2 downto 0);
        ads_7056_clock       : out std_logic;
        ads_7056_chip_select : out std_logic;
        ads_7056_input_data  : in std_logic;

        ad_mux2_io               : out std_logic_vector(2 downto 0);
        ads_7056_clock_pri       : out std_logic;
        ads_7056_chip_select_pri : out std_logic;
        ads_7056_input_data_pri  : in std_logic;

        grid_inu_sdm_data   : in std_logic;
        output_inu_sdm_data : in std_logic;
        dab_sdm_data        : in std_logic

        -- leds         : out std_logic_vector(3 downto 0)
    );
end entity titanium_top;

architecture rtl of titanium_top is

    use work.fpga_interconnect_pkg.all;
    use work.ads7056_pkg.all;
    use work.aux_pwm_pkg.all;
    use work.git_hash_pkg;
    use work.sigma_delta_cic_filter_pkg.all;
    use work.pwm_pkg.all;
    use work.real_to_fixed_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_top : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_signal_scope : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_measurements : fpga_interconnect_record := init_fpga_interconnect;

    signal trigger_event : boolean;
    signal sampled_data : std_logic_vector(15 downto 0);

    signal test_data : natural range 0 to 2**16-1 := 44252;
    signal test_data2 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal test_data3 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal mux_selection : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_counter : natural range 0 to 1023 := 0;

    signal aux_pwm : aux_pwm_record := init_aux_period_and_duty(period => 500, duty_cycle => 220);

    signal grid_inu_filter : cic_filter_record := init_cic_filter;
    signal output_inu_filter : cic_filter_record := init_cic_filter;
    signal dab_filter : cic_filter_record := init_cic_filter;
    signal sdm_counter : natural range 0 to 15 := 0;

    signal pwm : pwm_record := init_pwm;
    signal test_counter : natural range 0 to 2**16-1 := 0;
    
    package mpy_pkg is new work.multiplier_generic_pkg generic map(24,1,1);
        use mpy_pkg.all;

    package div_pkg is new work.division_generic_pkg generic map(mpy_pkg, g_max_shift => 8);
        use div_pkg.all;

    signal div_mpy : multiplier_record := init_multiplier;
    signal divider : division_record   := init_division;

    signal conversion_requested : boolean := false;

    constant instruction_length : natural := 32;
    constant word_length : natural := 32;
    constant used_radix : natural := 20;
    
    use work.real_to_fixed_pkg.all;
    function to_fixed is new generic_to_fixed 
    generic map(word_length => word_length, used_radix => used_radix);

    use work.microinstruction_pkg.all;

    use work.multi_port_ram_pkg.all;
    constant ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 3, datawidth => word_length, addresswidth => 10);
    signal ram_read_in  : ref_subtype.ram_read_in'subtype;
    signal ram_read_out : ref_subtype.ram_read_out'subtype;
    signal ram_write_in : ref_subtype.ram_write_in'subtype;

    constant instr_ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 1, datawidth => 32, addresswidth => 10);

    signal mc_read_in  : ref_subtype.ram_read_in'subtype;
    signal mc_read_out : ref_subtype.ram_read_out'subtype;
    signal mc_output   : ref_subtype.ram_write_in'subtype;

    use work.ram_connector_pkg.all;

    constant readports : natural := 3;
    constant addresswidth : natural := 10;
    constant datawidth : natural := word_length;
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

    signal ram_connector : ram_connector_ref'subtype;

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
        , 128 => op(set_rpt     , 200)
        , 129 => op(neg_mpy_add , inductor_voltage , duty             , cap_voltage      , input_voltage)
        , 130 => op(mpy_sub     , cap_current      , duty             , inductor_current , load)
        , 136 => op(neg_mpy_add , inductor_voltage , ind_res          , inductor_current , inductor_voltage)
        , 137 => op(mpy_add     , cap_voltage      , cap_current      , voltage_gain     , cap_voltage)
        , 140 => op(jump        , 129)
        , 143 => op(mpy_add     , inductor_current , inductor_voltage , current_gain     , inductor_current)

        , others => op(nop));

    ----
    signal ext_input : std_logic_vector(word_length-1 downto 0) := to_fixed(-22.351);

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
        
begin

    grid_inu_leg1_hi  <= '0';
    grid_inu_leg1_low <= '0';
    grid_inu_leg2_hi  <= '0';
    -- grid_inu_leg2_low <= '0';

    dab_primary_hi    <= '0';
    dab_primary_low   <= '0';
    dab_secondary_hi  <= '0';
    dab_secondary_low <= '0';

    output_inu_leg1_hi  <= '0';
    output_inu_leg1_low <= '0';
    output_inu_leg2_hi  <= '0';
    output_inu_leg2_low <= '0';

    primary_bypass_relay   <= '0';
    secondary_bypass_relay <= '0';

------------------------------------------------------------------------
    process(main_clock) is
    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_top);

            create_pwm(pwm,grid_inu_leg2_low);
            
            connect_data_to_address(bus_from_communications , bus_from_top , 1 , test_data);
            connect_data_to_address(bus_from_communications , bus_from_top , 4 , test_data2);

            if write_is_requested_to_address(bus_from_communications, 10) and get_data(bus_from_communications) = 1 then
                pwm.is_enabled <= true;
            end if;
            if write_is_requested_to_address(bus_from_communications, 10) and (get_data(bus_from_communications) /= 1) then
                pwm.is_enabled <= false;
            end if;

            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 6 , 2**15 + get_cic_filter_output(grid_inu_filter));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 7 , 2**15 + get_cic_filter_output(output_inu_filter));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 8 , 2**15 + get_cic_filter_output(dab_filter));


            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 100 , git_hash_pkg.git_hash(31 downto 16));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 101 , git_hash_pkg.git_hash(15 downto 0));

            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 500 , ext_input(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 501 , lc_load(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 502 , lc_duty(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 503 , lc_input_voltage(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 504 , simcurrent(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 505 , simvoltage(used_radix + 5 downto used_radix+5-15));

            ad_mux1_io <= test_data3(2 downto 0);
            ad_mux2_io <= test_data3(2 downto 0);

            adc_counter <= adc_counter + 1;
            conversion_requested <= false;
            if adc_counter > 1000 then
                conversion_requested <= true;
                adc_counter <= 0;
            end if;

            create_aux_pwm(aux_pwm);
            if test_data2(0) then
                start_aux_pwm(aux_pwm);
            end if;
            gate_power1_pwm <= aux_pwm.pwm_out and test_data2(1);
            gate_power2_pwm <= aux_pwm.pwm_out and test_data2(2);
            gate_power3_pwm <= aux_pwm.pwm_out and test_data2(3);
            gate_power4_pwm <= aux_pwm.pwm_out and test_data2(4);
            gate_power5_pwm <= aux_pwm.pwm_out and test_data2(5);
            gate_power6_pwm <= aux_pwm.pwm_out and test_data2(6);

            if sdm_counter < 5 then
                sdm_counter <= sdm_counter + 1;
            else
                sdm_counter <= 0;
                calculate_cic_filter(grid_inu_filter   , grid_inu_sdm_data);
                calculate_cic_filter(output_inu_filter , output_inu_sdm_data);
                calculate_cic_filter(dab_filter        , dab_sdm_data);
            end if;

            if sdm_counter > 5/2 then
                grid_inu_sdm_clock   <= '0';
                output_inu_sdm_clock <= '0';
                dab_sdm_clock        <= '0';
            else
                grid_inu_sdm_clock   <= '1';
                output_inu_sdm_clock <= '1';
                dab_sdm_clock        <= '1';
            end if;

            if test_counter < 4000 then
                test_counter <= test_counter + 1;
            else
                test_counter <= 0;
            end if;

        end if;
    end process;

------------------------------------------------------------------------
    u_measurements : entity work.measurements
    port map (
        main_clock => main_clock

        , ads_7056_chip_select_pri => ads_7056_chip_select_pri
        , ads_7056_clock_pri       => ads_7056_clock_pri
        , ads_7056_input_data_pri  => ads_7056_input_data_pri

        , ads_7056_chip_select => ads_7056_chip_select
        , ads_7056_clock       => ads_7056_clock
        , ads_7056_input_data  => ads_7056_input_data

         , test_data3              => test_data3
         , conversion_requested    => conversion_requested
         , bus_from_communications => bus_from_communications
         , bus_from_measurements   => bus_from_measurements

    );
------------------------------------------------------------------------
    u_signal_scope : entity work.signal_scope
        generic map( 16, 8)
        port map(
            main_clock
            ,bus_from_communications
            ,bus_from_signal_scope
            ,trigger_event
            ,true
            ,sampled_data
        );

    sampled_data <= std_logic_vector(to_unsigned(test_counter, 16));
    trigger_event <= test_counter = 3e3;

------------------------------------------------------------------------
    bus_to_communications <= bus_from_top 
                             and bus_from_signal_scope 
                             and bus_from_measurements 
                             when rising_edge(main_clock);

    u_fpga_communications : entity work.fpga_communications
    generic map(fpga_interconnect_pkg => work.fpga_interconnect_pkg)
        port map(
            clock                    => main_clock
            ,uart_rx                 => uart_rx
            ,uart_tx                 => uart_tx
            ,bus_to_communications   => bus_to_communications
            ,bus_from_communications => bus_from_communications
        );
        
------------------------------------------------------------------------
    process(main_clock) is
    begin
        if rising_edge(main_clock)
        then
            start_counter <= start_counter + 1;
            if start_counter > 50
            then
                start_counter <= 0;
            end if;

            init_mproc(mproc_in);
            if start_counter = 0
            then
                calculate(mproc_in, 129);
            end if;

            init_ram_connector(ram_connector);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 120, ext_input);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 121, lc_load);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 122, lc_duty);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 123, lc_input_voltage);
            connect_ram_write_to_address(mc_output , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_output , cap_voltage      , simvoltage);

        end if;
    end process;

------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_processor
    generic map(g_used_radix => used_radix, g_program => test_program, g_data => program_data)
    port map(main_clock, mproc_in, mproc_out, mc_read_in, mc_read_out, mc_output);
------------------------------------------------------------------------
end rtl;
