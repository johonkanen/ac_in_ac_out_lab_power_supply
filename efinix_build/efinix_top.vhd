library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity efinix_top is
    port (
        clock_120Mhz : in std_logic;
        uart_rx      : in std_logic;
        uart_tx      : out std_logic;
        aux_pwm_out  : out std_logic;

        grid_inu_sdm_clock   : out std_logic;
        output_inu_sdm_clock : out std_logic;
        dab_sdm_clock        : out std_logic;

        grid_inu_sdm_data   : in std_logic;
        output_inu_sdm_data : in std_logic;
        dab_sdm_data        : in std_logic;

        leds         : out std_logic_vector(3 downto 0)
    );
end entity efinix_top;


architecture rtl of efinix_top is

begin

    u_system_control : entity work.system_control
    port map( 
          system_clocks.clock_120mhz => clock_120mhz ,
          system_control_FPGA_in.communications_FPGA_in.uart_FPGA_in.uart_transreceiver_FPGA_in.uart_rx_fpga_in.uart_rx => uart_rx,

          system_control_FPGA_in.power_electronics_FPGA_in.dab_sdm_data    => dab_sdm_data        ,
          system_control_FPGA_in.power_electronics_FPGA_in.grid_sdm_data   => grid_inu_sdm_data   ,
          system_control_FPGA_in.power_electronics_FPGA_in.output_sdm_data => output_inu_sdm_data ,

          system_control_FPGA_out.power_electronics_FPGA_out.leds                 => leds                 ,
          system_control_FPGA_out.power_electronics_FPGA_out.dab_sdm_clock        => grid_inu_sdm_clock   ,
          system_control_FPGA_out.power_electronics_FPGA_out.grid_inu_sdm_clock   => output_inu_sdm_clock ,
          system_control_FPGA_out.power_electronics_FPGA_out.output_inu_sdm_clock => dab_sdm_clock        ,
          system_control_FPGA_out.power_electronics_FPGA_out.aux_pwm_out          => aux_pwm_out          ,

          system_control_FPGA_out.communications_FPGA_out.uart_FPGA_out.uart_transreceiver_FPGA_out.uart_tx_fpga_out.uart_tx => uart_tx);

end rtl;
