LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    -- use work.uart_tx_pkg.all;
    -- use work.uart_rx_pkg.all;
    -- use work.fpga_interconnect_pkg.all;
    -- use work.uart_protocol_pkg.all;

entity top_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of top_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 15000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal clock_120Mhz : std_logic;
    signal pll_locked   : std_logic;

    signal uart_rx      : std_logic;
    signal uart_tx      : std_logic;

    signal grid_inu_leg1_hi  : std_logic;
    signal grid_inu_leg1_low : std_logic;
    signal grid_inu_leg2_hi  : std_logic;
    signal grid_inu_leg2_low : std_logic;

    signal dab_primary_hi    : std_logic;
    signal dab_primary_low   : std_logic;
    signal dab_secondary_hi  : std_logic;
    signal dab_secondary_low : std_logic;

    signal output_inu_leg1_hi  : std_logic;
    signal output_inu_leg1_low : std_logic;
    signal output_inu_leg2_hi  : std_logic;
    signal output_inu_leg2_low : std_logic;

    signal primary_bypass_relay   : std_logic;
    signal secondary_bypass_relay : std_logic;

    signal gate_power1_pwm : std_logic;
    signal gate_power2_pwm : std_logic;
    signal gate_power3_pwm : std_logic;
    signal gate_power4_pwm : std_logic;
    signal gate_power5_pwm : std_logic;
    signal gate_power6_pwm : std_logic;

    signal grid_inu_sdm_clock   : std_logic;
    signal output_inu_sdm_clock : std_logic;
    signal dab_sdm_clock        : std_logic;

    signal ad_mux1_io           : std_logic_vector(2 downto 0);
    signal ads_7056_clock       : std_logic;
    signal ads_7056_chip_select : std_logic;
    signal ads_7056_input_data  : std_logic;

    signal ad_mux2_io               : std_logic_vector(2 downto 0);
    signal ads_7056_clock_pri       : std_logic;
    signal ads_7056_chip_select_pri : std_logic;
    signal ads_7056_input_data_pri  : std_logic;

    signal grid_inu_sdm_data   : std_logic;
    signal output_inu_sdm_data : std_logic;
    signal dab_sdm_data        : std_logic;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------
    process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
        end if;
    end process;
------------------------------------------------------------------------
    clock_120Mhz <= simulator_clock;

    u_top : entity work.top
    port map(
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

    ad_mux1_io           => ad_mux1_io,
    ads_7056_clock       => ads_7056_clock,
    ads_7056_chip_select => ads_7056_chip_select,
    ads_7056_input_data  => ads_7056_input_data,

    ad_mux2_io               => ad_mux2_io,
    ads_7056_clock_pri       => ads_7056_clock_pri,
    ads_7056_chip_select_pri => ads_7056_chip_select_pri,
    ads_7056_input_data_pri  => ads_7056_input_data_pri,

    grid_inu_sdm_data   => grid_inu_sdm_data,
    output_inu_sdm_data => output_inu_sdm_data,
    dab_sdm_data        => dab_sdm_data
);
------------------------------------------------------------------------
end vunit_simulation;
