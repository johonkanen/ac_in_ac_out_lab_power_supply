library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity cyclone_top is
    port (
        xclk : in std_logic;
        uart_rx      : in std_logic;
        uart_tx      : out std_logic;
        leds         : out std_logic_vector(3 downto 0)
    );
end entity cyclone_top;

architecture rtl of cyclone_top is

    signal clock_120Mhz : std_logic; 

    component main_clocks IS
	PORT
	(
		inclk0 : IN STD_LOGIC    := '0';
		c0     : OUT STD_LOGIC 
	);
    END component;


begin

    u_main_clocks : main_clocks
    port map(xclk, clock_120Mhz);

    u_efinix : entity work.efinix_top
    port map (
        clock_120Mhz => clock_120Mhz,
        uart_rx      => uart_rx,
        uart_tx      => uart_tx,
        leds         => leds
    );

end rtl;
