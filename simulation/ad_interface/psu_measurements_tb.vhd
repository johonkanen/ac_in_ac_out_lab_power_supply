LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity psu_measurements_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of psu_measurements_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    use work.meas_pkg.all;
    use work.adc_scaler_pkg.all;

    signal self_in  : adc_scaler_in_record(data_in(word_length-1 downto 0));
    signal self_out : adc_scaler_out_record(data_out(word_length-1 downto 0));

    signal sampled_pri_mux_pos : natural := 0;
    signal sampled_sec_mux_pos : natural := 0;

    signal sdm_counter : natural := 0;

    signal sdm1, sdm2, sdm3, spi1, spi2 : unsigned(15 downto 0) := (others => '0');
    signal sdm1_ready, sdm2_ready, sdm3_ready, spi1_ready, spi2_ready : boolean := false;
    signal sdm1_counter, sdm2_counter, sdm3_counter, spi1_counter, spi2_counter : natural := 0;

    procedure count_ready(is_ready : boolean; signal counter : inout integer) is
    begin
        if is_ready
        then
            counter <= counter + 1;
        end if;
    end count_ready;
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


        variable ready : boolean := false;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;


            sdm_counter <= sdm_counter + 1;
            if sdm_counter >= 5
            then
                sdm_counter <= 0;
            end if;

            if simulation_counter > 100
            then
                CASE sdm_counter is
                    WHEN 0 => 
                        sdm1 <= to_unsigned(5358  , 16);
                        sdm1_ready <= true;
                    WHEN 2 => 
                        sdm2 <= to_unsigned(10358 , 16);
                        sdm2_ready <= true;
                    WHEN 4 => 
                        sdm3 <= to_unsigned(15358 , 16);
                        sdm3_ready <= true;
                    WHEN others => --do nothing
                end CASE;

                if simulation_counter mod 13 = 0
                then
                    spi1 <= to_unsigned(8500, 16);
                    spi1_ready <= true;
                end if;

                if simulation_counter mod 17 = 0
                then
                    spi2 <= to_unsigned(3457, 16);
                    spi2_ready <= true;
                end if;
            end if;

            count_ready(sdm1_ready, sdm1_counter);
            count_ready(sdm2_ready, sdm2_counter);
            count_ready(sdm3_ready, sdm3_counter);
            count_ready(spi1_ready, spi1_counter);
            count_ready(spi2_ready, spi2_counter);

            init_adc_scaler(self_in);
            ---- scheduler
            ready := true;
            scale_measurement(self_in, sdm1_ready , ready , sdm1 , 1);
            scale_measurement(self_in, sdm2_ready , ready , sdm2 , 2);
            scale_measurement(self_in, sdm3_ready , ready , sdm3 , 3);
            scale_measurement(self_in, spi1_ready , ready , spi1 , 4);
            scale_measurement(self_in, spi2_ready , ready , spi2 , 5);


        end if; -- rising_edge
    end process stimulus;	

----------------
    u_adc_scaler : entity work.adc_scaler
    generic map(init_values, used_radix)
    port map(
        simulator_clock
        ,self_in
        ,self_out
    );
------------------------------------------------------------------------
end vunit_simulation;
