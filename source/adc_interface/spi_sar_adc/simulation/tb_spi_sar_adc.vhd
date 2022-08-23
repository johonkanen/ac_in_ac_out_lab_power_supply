LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.spi_sar_adc_pkg.all;

entity spi_sar_adc_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of spi_sar_adc_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    signal spi_sar_adc_clocks   : spi_sar_adc_clock_group;
    signal spi_sar_adc_FPGA_in  : spi_sar_adc_FPGA_input_group;
    signal spi_sar_adc_FPGA_out : spi_sar_adc_FPGA_output_group;
    signal spi_sar_adc_data_in  : spi_sar_adc_data_input_group;
    signal spi_sar_adc_data_out : spi_sar_adc_data_output_group;

    signal spi_adc_is_ready : boolean := false;
    signal spi_clock_out : std_logic;
    signal adc_measurement_data : natural :=0;


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

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            clocked_reset <= '1';
    
            simulation_counter <= simulation_counter + 1;

            idle_adc(spi_sar_adc_data_in);
            if simulation_counter = 55 then
                start_ad_conversion(spi_sar_adc_data_in);
            end if;

            spi_adc_is_ready <= ad_conversion_is_ready(spi_sar_adc_data_out);

            if ad_conversion_is_ready(spi_sar_adc_data_out) then
                adc_measurement_data <= get_adc_data(spi_sar_adc_data_out);
            end if;


        end if; -- rising_edge
    end process stimulus;	

    spi_clock_out <= spi_sar_adc_FPGA_out.spi_clock;
    spi_sar_adc_FPGA_in.spi_serial_data <= '1';

    u_spi_sar_adc : entity work.spi_sar_adc
    port map( (clock => simulator_clock, reset_n => clocked_reset),
          spi_sar_adc_FPGA_in,
    	  spi_sar_adc_FPGA_out,
    	  spi_sar_adc_data_in,
    	  spi_sar_adc_data_out);

end vunit_simulation;
