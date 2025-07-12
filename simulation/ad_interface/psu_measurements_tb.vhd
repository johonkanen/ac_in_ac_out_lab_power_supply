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

        procedure scale_measurement(
        signal requested : inout boolean 
        ; variable ready : inout boolean
        ; measurement : unsigned
        ; address : integer) is
        begin
            if requested and ready
            then
                request_scaling(self_in, resize(signed(measurement), word_length)
                ,address => address);
                requested <= false;
                ready := false;
            end if;
        end procedure;

        variable ready : boolean := false;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;


            sdm_counter <= sdm_counter + 1;
            if sdm_counter >= 5
            then
                sdm_counter <= 0;
            end if;

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

            init_adc_scaler(self_in);
            ---- scheduler
            ready := true;
            scale_measurement(sdm1_ready , ready , sdm1 , meas(iac_in));
            scale_measurement(sdm2_ready , ready , sdm2 , meas(iac_out));
            scale_measurement(sdm3_ready , ready , sdm3 , meas(i_dab));
            scale_measurement(spi1_ready , ready , spi1 , meas(vfilter_in));
            scale_measurement(spi2_ready , ready , spi2 , meas(vfilter_in));

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
