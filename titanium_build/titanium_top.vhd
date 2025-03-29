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

    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;
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

    ---- measurement module signals
    constant pri_input_voltage_gain   : real := 1.0/16.763636363636365;
    constant pri_input_voltage_offset : real := 8137.90909090909 * pri_input_voltage_gain;

    constant pri_dc_link_gain   : real := 1.0/16.857479572273963;
    constant pri_dc_link_offset : real := -15.196959245805374 * pri_dc_link_gain;

    constant pri_bridge_voltage_gain   : real := -1.0/16.327272727272728;
    constant pri_bridge_voltage_offset : real := 8153.272727272727 * pri_bridge_voltage_gain;

    signal meas_mult : multiplier_record := init_multiplier;

    signal conversion_requested : boolean := false;

    signal pri_input_voltage   : mpy_signed := (others => '0');
    signal pri_dc_link_voltage : mpy_signed := (others => '0');
    signal pri_bridge_voltage  : mpy_signed := (others => '0');
    signal conversion_is_ready : boolean := false;

    signal sample_and_hold_delay_counter : natural range 0 to 255;
    signal mux_counter : natural range 0 to 3 := 0;
    signal pri_mux_pos : natural range 0 to 7 := 0;
    signal conversion_mux_pos : natural range 0 to 7 := 0;

    signal pri_offset : mpy_signed := (others => '0');
    signal pri_gain   : mpy_signed := (others => '0');

    signal conversion_counter : natural range 0 to 7 := 0;

    ---- end measurement module signals
        
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
    measurement_scaling : process(main_clock)
    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_measurements);

            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 2  , get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 3  , get_converted_measurement(sec_ads7056));
            connect_data_to_address(bus_from_communications           , bus_from_measurements , 5  , test_data3);
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 9  , std_logic_vector(pri_input_voltage(15+2 downto 0+2)));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 10 , std_logic_vector(pri_dc_link_voltage(15+2 downto 0+2)));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 11 , std_logic_vector(pri_bridge_voltage(15+2 downto 0+2)));

            create_multiplier(meas_mult);

            create_ads7056_driver(pri_ads7056         
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);

            if conversion_requested then
                request_conversion(pri_ads7056);
                request_conversion(sec_ads7056);
            end if;

            if ad_conversion_is_ready(pri_ads7056) then
                conversion_counter <= 0;
                sample_and_hold_delay_counter <= 0;
            end if;

            conversion_mux_pos <= to_integer(unsigned(test_data3(2 downto 0)));
            conversion_is_ready <= false;
            CASE conversion_counter is
                WHEN 0 =>
                    conversion_counter <= conversion_counter + 1;
                    CASE conversion_mux_pos is
                        WHEN 0 => 
                            pri_offset <= to_fixed(pri_input_voltage_offset , mpy_signed'length , 10);
                            pri_gain   <= to_fixed(pri_input_voltage_gain   , mpy_signed'length , mpy_signed'length-1);
                        WHEN 1 => 
                            pri_offset <= to_fixed(pri_dc_link_offset , mpy_signed'length , 10);
                            pri_gain   <= to_fixed(pri_dc_link_gain   , mpy_signed'length , mpy_signed'length-1);
                        WHEN 3 => 
                            pri_offset <= to_fixed(pri_bridge_voltage_offset , mpy_signed'length , 10);
                            pri_gain   <= to_fixed(pri_bridge_voltage_gain   , mpy_signed'length , mpy_signed'length-1);

                        WHEN others => -- do nothing?
                    end CASE;
                WHEN 1 =>
                    conversion_counter <= conversion_counter + 1;
                    multiply(meas_mult, resize(signed(get_converted_measurement(pri_ads7056)), mpy_signed'length), pri_gain);
                WHEN 2 =>
                    if multiplier_is_ready(meas_mult) then
                        conversion_counter  <= conversion_counter + 1;
                        conversion_is_ready <= true;
                        CASE conversion_mux_pos is 
                            WHEN 0 => pri_input_voltage   <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, 10) - pri_offset;
                            WHEN 1 => pri_dc_link_voltage <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, 10) - pri_offset;
                            WHEN 3 => pri_bridge_voltage  <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, 10) - pri_offset;
                            WHEN others => --do nothing
                        end CASE;
                    end if;
                WHEN others => --do nothing
            end CASE;

        end if;
    end process;
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
end rtl;
