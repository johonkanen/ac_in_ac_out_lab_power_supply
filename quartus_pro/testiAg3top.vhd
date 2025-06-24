library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity testiAg3 is
    port (
        xclk : in std_logic
        ;led : out std_logic_vector(2 downto 0)
    );
end entity testiAg3;

architecture rtl of testiAg3 is
    -- signal counter : natural := 0;
	component main_clock is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk,   The reference clock source that drives the I/O PLL.
		rst      : in  std_logic := '0'; --   reset.reset, The asynchronous reset port for the output clocks. Drive this port high to reset all output clocks to the value of 0.
		outclk_0 : out std_logic         -- outclk0.clk,   Output clock Channel 0 from I/O PLL.
	);
	end component;
	
	signal core_clock : std_logic;
	 
begin
	u_main_clock : main_clock
	port map(refclk => xclk
				,outclk_0 => core_clock);

    led <= (others => '1');

end rtl;
