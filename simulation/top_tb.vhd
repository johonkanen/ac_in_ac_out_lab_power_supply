LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.uart_protocol_pkg.all;

entity top_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of top_tb is

    package uart_protocol_test_pkg is new work.serial_protocol_generic_test_pkg
        generic map(work.uart_protocol_pkg);
    use uart_protocol_test_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 40000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal uart_rx_data_in  : uart_rx_data_input_group := (number_of_clocks_per_bit => 24);
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_data_in    : uart_tx_data_input_group := init_uart_tx(24);
    signal uart_tx_data_out   : uart_tx_data_output_group;
    signal uart_protocol : serial_communcation_record := init_serial_communcation;

    signal number_of_registers_to_stream : integer range 0 to 2**23-1 := 0;
    signal stream_address : integer range 0 to 2**16-1 := 0;

    signal fpga_controlled_stream_requested : boolean := false;

    type std16_array is array (natural range <>) of std_logic_vector(15 downto 0);
    signal test_data : std16_array(1 to 5) := (others => (others => '1'));

    signal tuitui : std_logic_vector(15 downto 0) := (others => '0');

    signal transmit_counter : natural := 1;

    constant data_to_be_transmitted : std16_array :=(1 => x"acdc", 2 => x"abcd", 3=> x"1234", 4=>  x"1111", 5 => x"0101");

    constant g_clock_divider : integer := 24;

    signal bus_to_communications : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

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
    signal ads_7056_input_data  : std_logic := '1';

    signal ad_mux2_io               : std_logic_vector(2 downto 0);
    signal ads_7056_clock_pri       : std_logic;
    signal ads_7056_chip_select_pri : std_logic;
    signal ads_7056_input_data_pri  : std_logic := '1';

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

            init_uart(uart_tx_data_in, g_clock_divider);
            set_number_of_clocks_per_bit(uart_rx_data_in, g_clock_divider);
            create_serial_protocol(uart_protocol, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            CASE simulation_counter is
                WHEN 100 => transmit_words_with_serial(uart_protocol,read_frame(1000));
                WHEN 4600 => transmit_words_with_serial(uart_protocol,read_frame(1001));
                WHEN 6000 => transmit_words_with_serial(uart_protocol,stream_frame(1002, 40));
                WHEN others => -- do nothing
            end case;

            init_bus(bus_to_communications);
            connect_data_to_address(bus_from_communications, bus_to_communications, 1, test_data(1));
            connect_data_to_address(bus_from_communications, bus_to_communications, 2, test_data(2));
            connect_data_to_address(bus_from_communications, bus_to_communications, 3, test_data(3));
            connect_data_to_address(bus_from_communications, bus_to_communications, 4, test_data(4));
            connect_data_to_address(bus_from_communications, bus_to_communications, 5, test_data(5));
        end if;
    end process;

------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map(clock => simulator_clock   ,
          uart_rx_FPGA_in.uart_rx => uart_rx ,
    	  uart_rx_data_in  => uart_rx_data_in     ,
    	  uart_rx_data_out => uart_rx_data_out); 
------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
        port map(clock           => simulator_clock ,
        uart_tx_fpga_out.uart_tx => uart_tx         ,
        uart_tx_data_in          => uart_tx_data_in ,
        uart_tx_data_out         => uart_tx_data_out);
------------------------------------------------------------------------
------------------------------------------------------------------------
    clock_120Mhz <= simulator_clock;

    u_titanium_top : entity work.titanium_top
    port map(
    main_clock => clock_120Mhz
    ,pll_locked => pll_locked

    ,uart_rx      => uart_tx
    ,uart_tx      => uart_rx

    ,grid_inu_leg1_hi  => grid_inu_leg1_hi
    ,grid_inu_leg1_low => grid_inu_leg1_low
    ,grid_inu_leg2_hi  => grid_inu_leg2_hi
    ,grid_inu_leg2_low => grid_inu_leg2_low

    ,dab_primary_hi    => dab_primary_hi
    ,dab_primary_low   => dab_primary_low
    ,dab_secondary_hi  => dab_secondary_hi
    ,dab_secondary_low => dab_secondary_low

    ,output_inu_leg1_hi  => output_inu_leg1_hi
    ,output_inu_leg1_low => output_inu_leg1_low
    ,output_inu_leg2_hi  => output_inu_leg2_hi
    ,output_inu_leg2_low => output_inu_leg2_low

    ,primary_bypass_relay   => primary_bypass_relay
    ,secondary_bypass_relay => secondary_bypass_relay

    ,gate_power1_pwm => gate_power1_pwm
    ,gate_power2_pwm => gate_power2_pwm
    ,gate_power3_pwm => gate_power3_pwm
    ,gate_power4_pwm => gate_power4_pwm
    ,gate_power5_pwm => gate_power5_pwm
    ,gate_power6_pwm => gate_power6_pwm

    ,grid_inu_sdm_clock   => grid_inu_sdm_clock
    ,output_inu_sdm_clock => output_inu_sdm_clock
    ,dab_sdm_clock        => dab_sdm_clock

    ,ad_mux1_io           => ad_mux1_io
    ,ads_7056_clock       => ads_7056_clock
    ,ads_7056_chip_select => ads_7056_chip_select
    ,ads_7056_input_data  => ads_7056_input_data

    ,ad_mux2_io               => ad_mux2_io
    ,ads_7056_clock_pri       => ads_7056_clock_pri
    ,ads_7056_chip_select_pri => ads_7056_chip_select_pri
    ,ads_7056_input_data_pri  => ads_7056_input_data_pri

    ,grid_inu_sdm_data   => grid_inu_sdm_data
    ,output_inu_sdm_data => output_inu_sdm_data
    ,dab_sdm_data        => dab_sdm_data
);
------------------------------------------------------------------------
end vunit_simulation;
