library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity testiAg3 is
    port (
        xclk                      : in  std_logic
        ;uart_rx                  : in  std_logic
        ;uart_tx                  : out std_logic
        ;grid_inu_sdm_data        : in  std_logic
        ;output_inu_sdm_data      : in  std_logic
        ;dab_sdm_data             : in  std_logic
        ;grid_inu_sdm_clock       : out std_logic
        ;output_inu_sdm_clock     : out std_logic
        ;dab_sdm_clock            : out std_logic
        ;enet_led                 : out std_logic
        ;enet_led1                : out std_logic

        ;ad_mux2_io               : out std_logic_vector(2 downto 0)
        ;ads_7056_clock           : out std_logic
        ;ads_7056_chip_select     : out std_logic
        ;ads_7056_input_data      : in  std_logic

        ;grid_inu_leg1_hi         : out std_logic
        ;grid_inu_leg1_low        : out std_logic
        ;grid_inu_leg2_hi         : out std_logic
        ;grid_inu_leg2_low        : out std_logic

        ;dab_primary_hi           : out std_logic
        ;dab_primary_low          : out std_logic
        ;dab_secondary_hi         : out std_logic
        ;dab_secondary_low        : out std_logic

        ;output_inu_leg1_hi       : out std_logic
        ;output_inu_leg1_low      : out std_logic
        ;output_inu_leg2_hi       : out std_logic
        ;output_inu_leg2_low      : out std_logic

        ;primary_bypass_relay     : out std_logic
        ;secondary_bypass_relay   : out std_logic

        ;gate_power1_pwm          : out std_logic
        ;gate_power2_pwm          : out std_logic
        ;gate_power3_pwm          : out std_logic
        ;gate_power4_pwm          : out std_logic
        ;gate_power5_pwm          : out std_logic
        ;gate_power6_pwm          : out std_logic

        ;ad_mux1_io               : out std_logic_vector(2 downto 0)
        ;ads_7056_clock_pri       : out std_logic
        ;ads_7056_chip_select_pri : out std_logic
        ;ads_7056_input_data_pri  : out std_logic
        ;extra                    : out std_logic
    );
end entity testiAg3;

architecture rtl of testiAg3 is

	component main_clock is
	port (
        refclk    : in  std_logic := '0'  -- refclk.clk,   The reference clock source that drives the I/O PLL.
        ;rst      : in  std_logic := '0' -- reset.reset, The asynchronous reset port for the output clocks. Drive this port high to reset all output clocks to the value of 0.
        ;outclk_0 : out std_logic        -- outclk0.clk,   Output clock Channel 0 from I/O PLL.
		  ;outclk_1 : out std_logic        -- outclk0.clk,   Output clock Channel 0 from I/O PLL.
	);
	end component;

    component reset_release is
    port (
        ninit_done : out std_logic   -- ninit_done
    );
    end component reset_release;

	 signal core_clock : std_logic;
	 signal core_clock_x2 : std_logic;
    signal init_done : std_logic;
    signal led_state : std_logic := '0';
    signal blink_counter : natural range 0 to 60e6 := 0;
	 
begin
	u_main_clock : main_clock
	port map(refclk => xclk,outclk_0 => core_clock, outclk_1 => core_clock_x2);

    u0 : component reset_release
        port map (
            ninit_done => init_done  -- ninit_done.ninit_done
        );
		  
	enet_led <= '1';

    process(core_clock)
    begin
        if rising_edge(core_clock)
        then
            blink_counter <= blink_counter + 1;
            if blink_counter = 60e6-1
            then
                blink_counter <= 0;
                led_state <= not led_state;
            end if;
            enet_led1 <= led_state;

            grid_inu_leg1_hi         <= led_state;
            grid_inu_leg1_low        <= led_state;
            grid_inu_leg2_hi         <= led_state;
            grid_inu_leg2_low        <= led_state;
            dab_primary_hi           <= led_state;
            dab_primary_low          <= led_state;
            dab_secondary_hi         <= led_state;
            dab_secondary_low        <= led_state;
            output_inu_leg1_hi       <= led_state;
            output_inu_leg1_low      <= led_state;
            output_inu_leg2_hi       <= led_state;
            output_inu_leg2_low      <= led_state;
            primary_bypass_relay     <= led_state;
            secondary_bypass_relay   <= led_state;

            gate_power1_pwm          <= led_state;
            gate_power2_pwm          <= led_state;
            gate_power3_pwm          <= led_state;
            gate_power4_pwm          <= led_state;
            gate_power5_pwm          <= led_state;
            gate_power6_pwm          <= led_state;

            ad_mux1_io               <= (others => led_state);
            ads_7056_clock_pri       <= led_state;
            ads_7056_chip_select_pri <= led_state;
            ads_7056_input_data_pri  <= led_state;

            extra                    <= led_state;

        end if;
    end process;
	

    u_titanium_top : entity work.titanium_top
    port map (
        main_clock                => core_clock
		  ,main_clock_x2				 => core_clock_x2
        ,pll_locked               => init_done
        ,uart_rx                  => uart_rx
        ,uart_tx                  => uart_tx
        ,grid_inu_leg1_hi         => open
        ,grid_inu_leg1_low        => open
        ,grid_inu_leg2_hi         => open
        ,grid_inu_leg2_low        => open
        ,dab_primary_hi           => open
        ,dab_primary_low          => open
        ,dab_secondary_hi         => open
        ,dab_secondary_low        => open
        ,output_inu_leg1_hi       => open
        ,output_inu_leg1_low      => open
        ,output_inu_leg2_hi       => open
        ,output_inu_leg2_low      => open
        ,primary_bypass_relay     => open
        ,secondary_bypass_relay   => open
        ,gate_power1_pwm          => open
        ,gate_power2_pwm          => open
        ,gate_power3_pwm          => open
        ,gate_power4_pwm          => open
        ,gate_power5_pwm          => open
        ,gate_power6_pwm          => open
        ,ad_mux2_io               => ad_mux2_io
        ,ads_7056_clock           => ads_7056_clock      
        ,ads_7056_chip_select     => ads_7056_chip_select
        ,ads_7056_input_data      => ads_7056_input_data 
        ,ad_mux1_io               => open          
        ,ads_7056_clock_pri       => open
        ,ads_7056_chip_select_pri => open
        ,ads_7056_input_data_pri  => '0'
        ,grid_inu_sdm_data        => grid_inu_sdm_data   
        ,output_inu_sdm_data      => output_inu_sdm_data 
        ,dab_sdm_data             => dab_sdm_data        
        ,grid_inu_sdm_clock       => grid_inu_sdm_clock  
        ,output_inu_sdm_clock     => output_inu_sdm_clock
        ,dab_sdm_clock            => dab_sdm_clock       
    );

end rtl;
