library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity efinix_top is
    port (
        clock_120Mhz : in std_logic;
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
        dab_sdm_data        : in std_logic;

        leds         : out std_logic_vector(3 downto 0)
    );
end entity efinix_top;


architecture rtl of efinix_top is

    signal aux_pwm : std_logic := '0';

begin

    grid_inu_leg1_hi  <= '0';
    grid_inu_leg1_low <= '0';
    grid_inu_leg2_hi  <= '0';
    grid_inu_leg2_low <= '0';

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

    gate_power6_pwm <= aux_pwm;
    gate_power5_pwm <= aux_pwm;
    gate_power4_pwm <= aux_pwm;
    gate_power3_pwm <= aux_pwm;
    gate_power2_pwm <= aux_pwm;
    gate_power1_pwm <= aux_pwm;

    u_system_control : entity work.system_control
    port map( 
          system_clocks.clock_120mhz => clock_120mhz ,
          system_control_FPGA_in.communications_FPGA_in.uart_FPGA_in.uart_transreceiver_FPGA_in.uart_rx_fpga_in.uart_rx => uart_rx,

          system_control_FPGA_in.power_electronics_FPGA_in.dab_sdm_data    => dab_sdm_data        ,
          system_control_FPGA_in.power_electronics_FPGA_in.grid_sdm_data   => grid_inu_sdm_data   ,
          system_control_FPGA_in.power_electronics_FPGA_in.output_sdm_data => output_inu_sdm_data ,

          system_control_FPGA_in.power_electronics_FPGA_in.spi_data1  => ads_7056_input_data  ,
          system_control_FPGA_in.power_electronics_FPGA_in.spi_data2 => ads_7056_input_data_pri  ,

          system_control_FPGA_out.power_electronics_FPGA_out.ad_mux_channel_select1            => ad_mux1_io           ,
          system_control_FPGA_out.power_electronics_FPGA_out.chip_select1  => ads_7056_chip_select ,
          system_control_FPGA_out.power_electronics_FPGA_out.spi_clock1    => ads_7056_clock       ,

          system_control_FPGA_out.power_electronics_FPGA_out.ad_mux_channel_select2            => ad_mux2_io               ,
          system_control_FPGA_out.power_electronics_FPGA_out.chip_select2 => ads_7056_chip_select_pri ,
          system_control_FPGA_out.power_electronics_FPGA_out.spi_clock2   => ads_7056_clock_pri       ,

          system_control_FPGA_out.power_electronics_FPGA_out.leds                 => leds                 ,
          system_control_FPGA_out.power_electronics_FPGA_out.dab_sdm_clock        => grid_inu_sdm_clock   ,
          system_control_FPGA_out.power_electronics_FPGA_out.grid_inu_sdm_clock   => output_inu_sdm_clock ,
          system_control_FPGA_out.power_electronics_FPGA_out.output_inu_sdm_clock => dab_sdm_clock        ,
          system_control_FPGA_out.power_electronics_FPGA_out.aux_pwm_out          => aux_pwm              ,

          system_control_FPGA_out.communications_FPGA_out.uart_FPGA_out.uart_transreceiver_FPGA_out.uart_tx_fpga_out.uart_tx => uart_tx);

end rtl;
