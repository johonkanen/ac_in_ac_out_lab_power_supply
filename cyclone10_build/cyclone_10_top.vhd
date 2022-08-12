library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity cyclone_top is
    port (
        xclk : in std_logic;
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

        leds         : out std_logic_vector(3 downto 0)
    );
end entity cyclone_top;

architecture rtl of cyclone_top is

    signal clock_120Mhz : std_logic; 

    component main_clocks IS
	PORT
	(
		inclk0 : IN STD_LOGIC  := '0';
		c0     : OUT STD_LOGIC;
		locked : OUT STD_LOGIC
	);
    END component;

    signal aux_pwm : std_logic := '0';

    signal sdm_clock_counter : integer range 0 to 2**4-1 := 0;
    signal sdm_io_clock : std_logic := '0';

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

------------------------------------------------------------------------
    u_main_clocks : main_clocks
    port map(xclk, clock_120Mhz, open);
------------------------------------------------------------------------

    test_sdm_clocks : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then
            if sdm_clock_counter > 0 then
                sdm_clock_counter <= sdm_clock_counter - 1;
            else
                sdm_clock_counter <= 2;
                sdm_io_clock <= not sdm_io_clock;
            end if;

            grid_inu_sdm_clock   <= sdm_io_clock;
            output_inu_sdm_clock <= sdm_io_clock;
            dab_sdm_clock        <= sdm_io_clock;

        end if; --rising_edge
    end process test_sdm_clocks;	

------------------------------------------------------------------------
    u_efinix : entity work.efinix_top
    port map (
        clock_120Mhz => clock_120Mhz,
        uart_rx      => uart_rx,
        uart_tx      => uart_tx,
        aux_pwm_out  => aux_pwm,
        leds         => leds
    );

end rtl;
