library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;

entity efinix_top is
    port (
        clock_120Mhz : in std_logic;
        uart_rx      : in std_logic;
        uart_tx      : out std_logic;
        leds         : out std_logic_vector(3 downto 0)
    );
end entity efinix_top;


architecture rtl of efinix_top is

begin

    u_system_control : entity work.system_control
    port map( 
          system_control_clocks.clock_120mhz => clock_120mhz ,
          system_control_FPGA_in.component_interconnect_FPGA_in.communications_FPGA_in.uart_FPGA_in.uart_transreceiver_FPGA_in.uart_rx_fpga_in.uart_rx => uart_rx,
          system_control_FPGA_out.component_interconnect_FPGA_out.power_electronics_FPGA_out.leds => leds,
          system_control_FPGA_out.component_interconnect_FPGA_out.communications_FPGA_out.uart_FPGA_out.uart_transreceiver_FPGA_out.uart_tx_fpga_out.uart_tx => uart_tx);

end rtl;
