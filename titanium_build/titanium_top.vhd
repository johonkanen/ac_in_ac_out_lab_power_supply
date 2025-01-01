library ieee;
    use ieee.std_logic_1164.all;

    use work.fpga_interconnect_pkg.all;
    use work.ads7056_pkg.all;

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

    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;
    signal mux_selection : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_counter : natural range 0 to 1023 := 0;

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

    gate_power1_pwm <= '0';
    gate_power2_pwm <= '0';
    gate_power3_pwm <= '0';
    gate_power4_pwm <= '0';
    gate_power5_pwm <= '0';
    gate_power6_pwm <= '0';

    grid_inu_sdm_clock   <= '0';
    output_inu_sdm_clock <= '0';
    dab_sdm_clock        <= '0';

    ad_mux1_io           <= "000";
    -- ads_7056_clock       <= '0';
    -- ads_7056_chip_select <= '1';

    ad_mux2_io               <= "000";
    -- ads_7056_clock_pri       <= '0';
    -- ads_7056_chip_select_pri <= '1';

    r_grid_inu_sdm_data   <= grid_inu_sdm_data;
    r_output_inu_sdm_data <= output_inu_sdm_data;
    r_dab_sdm_data        <= dab_sdm_data;

------------------------------------------------------------------------
    process(main_clock) is
    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_top);
            
            connect_data_to_address(bus_from_communications, bus_from_top, 1, test_data);
            bus_to_communications <= bus_from_top;
            adc_counter <= adc_counter + 1;

            create_ads7056_driver(pri_ads7056         
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);

            if adc_counter > 1000 then
                adc_counter <= 0;
                request_conversion(pri_ads7056);
                request_conversion(sec_ads7056);
            end if;
        end if;
    end process;
------------------------------------------------------------------------
    u_fpga_communications : entity work.fpga_communications
    generic map(fpga_interconnect_pkg => work.fpga_interconnect_pkg)
        port map(
            clock                   => main_clock            ,
            uart_rx                 => uart_rx               ,
            uart_tx                 => uart_tx               ,
            bus_to_communications   => bus_to_communications ,
            bus_from_communications => bus_from_communications
        );
------------------------------------------------------------------------
end rtl;
