library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity signal_scope is
    generic(g_ram_bit_width    : natural
            ;g_ram_depth_pow2  : natural
            ;g_trigger_address : positive := 1000
            ;g_data_address    : positive := 1001
            ;g_samples_after_trigger_address : positive := 1002
           );
    port (
      main_clock              : in std_logic
      ; bus_in                : in work.fpga_interconnect_pkg.fpga_interconnect_record
      ; bus_from_signal_scope : out work.fpga_interconnect_pkg.fpga_interconnect_record
      ; trigger_event1        : in boolean
      ; sample_event1         : in boolean
      ; sampled_data1         : in std_logic_vector
    );
end entity signal_scope;

architecture rtl of signal_scope is

    use work.fpga_interconnect_pkg.all;

    package scope_ram_port_pkg is new work.ram_port_generic_pkg 
        generic map(
            g_ram_bit_width    => g_ram_bit_width
            , g_ram_depth_pow2 => g_ram_depth_pow2);

    package scope_sample_trigger_pkg is new work.sample_trigger_generic_pkg 
        generic map(g_ram_depth => scope_ram_port_pkg.ram_depth);

    use scope_ram_port_pkg.all;
    use scope_sample_trigger_pkg.all;

    signal samples_after_trigger : natural range 0 to ram_depth-1 := ram_depth/2;

    procedure create_scope(
      signal trigger          : inout sample_trigger_record
      ; bus_in                : in fpga_interconnect_record
      ; signal bus_out        : out fpga_interconnect_record
      ; signal ram_port_in_a  : out ram_in_record
      ; signal ram_port_out_a : in ram_out_record
      ; signal ram_port_in_b  : out ram_in_record
      ; signal ram_port_out_b : in ram_out_record
      ; trigger_event          : in boolean
      ; sample_event          : in boolean
      ; sampled_data          : in std_logic_vector

    ) is
    begin
        create_trigger(trigger, trigger_event, sample_event);

        if sampling_enabled(trigger) and sample_event then
            write_data_to_ram(ram_port_in_b, get_write_address(trigger), sampled_data);
        end if;

        if data_is_requested_from_address(bus_in, g_trigger_address) then
            write_data_to_address(bus_out, address => 0, data => 3);
            prime_trigger(trigger, samples_after_trigger);
        end if;
        
        if data_is_requested_from_address(bus_in, g_data_address) then
            calculate_read_address(trigger);
            request_data_from_ram(ram_port_in_a, get_sample_address(trigger));
        end if;

        if ram_read_is_ready(ram_port_out_a) then
            write_data_to_address(bus_out, address => 0, data => get_ram_data(ram_port_out_a));
        end if;
    end create_scope;

    signal sample_trigger : sample_trigger_record := init_trigger;

    signal ram_a_in  : ram_in_record;
    signal ram_a_out : ram_out_record;
    --------------------
    signal ram_b_in  : ram_in_record;
    signal ram_b_out : ram_out_record;

begin

    process(main_clock) is
    begin
        if rising_edge(main_clock) then
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            init_bus(bus_from_signal_scope);

            connect_data_to_address(bus_in, bus_from_signal_scope, g_samples_after_trigger_address, samples_after_trigger);

            create_scope(sample_trigger
            , bus_in
            , bus_from_signal_scope
            , ram_a_in
            , ram_a_out
            , ram_b_in
            , ram_b_out
            , trigger_event1
            , sample_event1
            , sampled_data1
            );
        end if;
    end process;

    u_dpram : entity work.generic_dual_port_ram
    generic map(scope_ram_port_pkg)
    port map(
    main_clock ,
    ram_a_in   ,
    ram_a_out  ,
    --------------
    ram_b_in  ,
    ram_b_out);
------------------------------------------------------------------------
end rtl;
------------------------------------------------------------------------
------------------------------------------------------------------------
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

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_top : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_signal_scope : fpga_interconnect_record := init_fpga_interconnect;
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
    
    use ieee.fixed_pkg.all;
    signal a : std_logic_vector(15 downto 0);
    signal b : std_logic_vector(15 downto 0);
    signal adivb : std_logic_vector(15 downto 0);
    signal diva : ufixed(4 downto -11);
    signal divb : ufixed(4 downto -11);
    signal diva1 : ufixed(4 downto -11);
    signal divb1 : ufixed(4 downto -11);

    constant divdummy : ufixed := to_ufixed(3.0, 4, -11) / to_ufixed(2.0,4,-11);
    signal res1 : ufixed(divdummy'range) := to_ufixed(3.0, 4, -11) / to_ufixed(2.0,4,-11);
    signal res2 : ufixed(divdummy'range) := to_ufixed(3.0, 4, -11) / to_ufixed(2.0,4,-11);
    
    signal res : ufixed(divdummy'range) := to_ufixed(3.0, 4, -11) / to_ufixed(2.0,4,-11);

    package mpy_pkg is new work.multiplier_generic_pkg generic map(24,1,1);
        use mpy_pkg.all;
    package div_pkg is new work.division_generic_pkg generic map(mpy_pkg, g_max_shift => 8);
        use div_pkg.all;

    signal div_mpy : multiplier_record := init_multiplier;
    signal divider : division_record   := init_division;
        
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


            create_ads7056_driver(pri_ads7056         
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);

            create_pwm(pwm,grid_inu_leg2_low);
            
            connect_data_to_address(bus_from_communications , bus_from_top , 1 , test_data);

            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 2 , get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 3 , get_converted_measurement(sec_ads7056));

            connect_data_to_address(bus_from_communications , bus_from_top , 4 , test_data2);
            connect_data_to_address(bus_from_communications , bus_from_top , 5 , test_data3);

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

            -- connect_data_to_address(bus_from_communications , bus_from_top , 10 , a);
            -- connect_data_to_address(bus_from_communications , bus_from_top , 11 , b);
            --
            -- connect_read_only_data_to_address(bus_from_communications , bus_from_top , 12 , adivb);
            --
            -- diva1 <= ufixed(a);
            -- divb1 <= ufixed(b);
            -- diva <= diva1;
            -- divb <= divb1;
            -- res1 <= diva/divb;
            -- res2 <= res1;
            -- res <= res2;
            -- adivb <= to_slv(resize(res,diva));
            
            
            ad_mux1_io <= test_data3(2 downto 0);
            ad_mux2_io <= test_data3(2 downto 0);

            adc_counter <= adc_counter + 1;
            if adc_counter > 1000 then
                adc_counter <= 0;
                request_conversion(pri_ads7056);
                request_conversion(sec_ads7056);
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
    bus_to_communications <= bus_from_top and bus_from_signal_scope when rising_edge(main_clock);

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
