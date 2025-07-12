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

    signal bus_from_top          : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_uproc        : fpga_interconnect_record := init_fpga_interconnect;
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

    use work.main_state_machine_pkg.all;
    signal main_state_machine : main_state_record := init_main_state;

    signal precharge_delay_counter : natural range 0 to 65535 := 65535;
        
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

        ----------------------
        impure function start_requested return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 1;
        end start_requested;

        ----------------------
        impure function shutdown_requested return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 0;
        end shutdown_requested;

        ----------------------
        impure function acknowledge_fault return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 2;
        end acknowledge_fault;
        ----------------------
        procedure start_precharge is
        begin
            if precharge_delay_counter < integer(50.0e-3 * 120.0e6)
            then
                precharge_delay_counter <= precharge_delay_counter + 1;
            end if;

            if start_requested
            then
                precharge_delay_counter <= 0;
            end if;

        end start_precharge;
        ----------------------
        ----------------------
        procedure create_main_state_machine is new generic_main_state_machine 
            generic map(start_precharge);
        ----------------------

    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_top);

            create_main_state_machine(main_state_machine
                 , start_requested    => start_requested
                 , precharge_ready    => precharge_delay_counter = integer(50.0e-3 * 120.0e6)
                 , fault_detected     => false
                 , fault_acknowledged => acknowledge_fault
                 , shutdown_requested => shutdown_requested
            );

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
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 12 , report_state(main_state_machine));

            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 100 , git_hash_pkg.git_hash(31 downto 16));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 101 , git_hash_pkg.git_hash(15 downto 0));

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
    combine_buses : process(main_clock) is
    begin
        if rising_edge(main_clock)
        then
            bus_to_communications <= bus_from_top 
                                     and bus_from_signal_scope 
                                     and bus_from_measurements 
                                     and bus_from_uproc 
                                     ;
        end if; -- rising_edge
    end process;

------------------------------------------------------------------------
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
u_uproc_test : entity work.uproc_test
port map( 
    clock => main_clock
    ,bus_from_communications => bus_from_communications
    ,bus_from_uproc          => bus_from_uproc);
------------------------------------------------------------------------

end rtl;
