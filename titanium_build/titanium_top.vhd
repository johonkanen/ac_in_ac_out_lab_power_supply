library ieee;
    use ieee.std_logic_1164.all;

    use work.fpga_interconnect_pkg.all;
    use work.ads7056_pkg.all;
    use work.aux_pwm_pkg.all;
    use work.git_hash_pkg;

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

    signal r_grid_inu_sdm_data   : std_logic;
    signal r_output_inu_sdm_data : std_logic;
    signal r_dab_sdm_data        : std_logic;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_top : fpga_interconnect_record := init_fpga_interconnect;

    signal test_data : natural range 0 to 2**16-1 := 44252;
    signal test_data2 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal test_data3 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;
    signal mux_selection : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_counter : natural range 0 to 1023 := 0;

    signal aux_pwm : aux_pwm_record := init_aux_pwm_with_duty_cycle(75);

begin

    output_inu_leg1_hi  <= '0';
    output_inu_leg1_low <= '0';
    output_inu_leg2_hi  <= '0';
    output_inu_leg2_low <= '0';

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


    grid_inu_sdm_clock   <= '0';
    output_inu_sdm_clock <= '0';
    dab_sdm_clock        <= '0';


    r_grid_inu_sdm_data   <= grid_inu_sdm_data;
    r_output_inu_sdm_data <= output_inu_sdm_data;
    r_dab_sdm_data        <= dab_sdm_data;

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
            
            connect_data_to_address(bus_from_communications, bus_from_top, 1, test_data);
            connect_read_only_data_to_address(bus_from_communications, bus_from_top, 100, git_hash_pkg.git_hash(31 downto 16));
            connect_read_only_data_to_address(bus_from_communications, bus_from_top, 101, git_hash_pkg.git_hash(15 downto 0));
            
            connect_read_only_data_to_address(bus_from_communications, bus_from_top, 2, get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications, bus_from_top, 3, get_converted_measurement(sec_ads7056));
            connect_data_to_address(bus_from_communications, bus_from_top, 4, test_data2);
            connect_data_to_address(bus_from_communications, bus_from_top, 5, test_data3);
            bus_to_communications <= bus_from_top;

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

        end if;
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
end rtl;
