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
end entity cyclone_top;

architecture rtl of cyclone_top is

    signal clock_120Mhz : std_logic; 
    signal pll_locked : std_logic;

    component main_clocks IS
	PORT
	(
		inclk0 : IN STD_LOGIC  := '0';
		c0     : OUT STD_LOGIC;
		locked : OUT STD_LOGIC
	);
    END component;

begin


------------------------------------------------------------------------
    u_main_clocks : main_clocks
    port map(xclk, clock_120Mhz, pll_locked);
------------------------------------------------------------------------

------------------------------------------------------------------------
    u_efinix : entity work.efinix_top
    port map (
        clock_120Mhz => clock_120Mhz,
        pll_locked   => pll_locked,
        uart_rx      => uart_rx,
        uart_tx      => uart_tx,

        grid_inu_leg1_hi  => grid_inu_leg1_hi,
        grid_inu_leg1_low => grid_inu_leg1_low,
        grid_inu_leg2_hi  => grid_inu_leg2_hi,
        grid_inu_leg2_low => grid_inu_leg2_low,

        dab_primary_hi    => dab_primary_hi,
        dab_primary_low   => dab_primary_low,
        dab_secondary_hi  => dab_secondary_hi,
        dab_secondary_low => dab_secondary_low,

        output_inu_leg1_hi  => output_inu_leg1_hi,
        output_inu_leg1_low => output_inu_leg1_low,
        output_inu_leg2_hi  => output_inu_leg2_hi,
        output_inu_leg2_low => output_inu_leg2_low,

        primary_bypass_relay   => primary_bypass_relay,
        secondary_bypass_relay => secondary_bypass_relay,

        gate_power1_pwm => gate_power1_pwm,
        gate_power2_pwm => gate_power2_pwm,
        gate_power3_pwm => gate_power3_pwm,
        gate_power4_pwm => gate_power4_pwm,
        gate_power5_pwm => gate_power5_pwm,
        gate_power6_pwm => gate_power6_pwm,

        grid_inu_sdm_clock   => grid_inu_sdm_clock,
        output_inu_sdm_clock => output_inu_sdm_clock,
        dab_sdm_clock        => dab_sdm_clock,

        ad_mux1_io           => ad_mux1_io           ,
        ads_7056_clock       => ads_7056_clock       ,
        ads_7056_chip_select => ads_7056_chip_select ,
        ads_7056_input_data  => ads_7056_input_data  ,

        ad_mux2_io               => ad_mux2_io               ,
        ads_7056_clock_pri       => ads_7056_clock_pri       ,
        ads_7056_chip_select_pri => ads_7056_chip_select_pri ,
        ads_7056_input_data_pri  => ads_7056_input_data_pri  ,

        grid_inu_sdm_data   => grid_inu_sdm_data,
        output_inu_sdm_data => output_inu_sdm_data,
        dab_sdm_data        => dab_sdm_data,

        leds         => leds
    );

end rtl;
