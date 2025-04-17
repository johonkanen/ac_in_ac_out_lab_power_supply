
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity measurements_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of measurements_tb is

    package dp_ram_pkg is new work.ram_port_generic_pkg 
        generic map( g_ram_bit_width   => 16
                     ,g_ram_depth_pow2 => 10);

    use dp_ram_pkg.all;

    use work.fpga_interconnect_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 40000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal bus_to_measurements   : fpga_interconnect_record ;
    signal bus_from_measurements : fpga_interconnect_record ;
    signal ram_b_in              : ram_in_record            ;

    constant counter_max_800kHz : natural := 128e6/930e3;
    signal count_to_800khz : natural range 0 to 1000 := 0;

    type test_record is record
        counter : natural;
        enabled : boolean;
    end record test_record;

    constant init_test_record  : test_record := (0,false);

    signal test_record_p1 : test_record := init_test_record;
    signal test_record_p2 : test_record := init_test_record;

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

            ------------------------------------------
            if count_to_800khz < counter_max_800kHz 
            then
                count_to_800khz <= count_to_800khz + 1;
            else
                count_to_800khz <= 0;
            end if;

            if count_to_800khz = 0 
            then
                -- request_conversion(dab_adc);
                -- request_conversion(llc_adc);
            end if;
            ------------------------------------------

        end if;
    end process;
------------------------------------------------------------------------
    two_proc1 : process(all) is
        variable v_test_record : test_record := init_test_record;
    begin
        v_test_record := test_record_p2;
        v_test_record.counter := v_test_record.counter + 1;

        test_record_p1 <= v_test_record;
    end process two_proc1;
    two_proc2 : process(simulator_clock) is
    begin
        test_record_p2 <= test_record_p1;
    end process two_proc2;
------------------------------------------------------------------------
    u_measurements : entity work.measurements
    generic map(work.fpga_interconnect_pkg, dp_ram_pkg)
    port map(
        simulator_clock

        ,ada_mux   => open
        ,ada_clock => open
        ,ada_cs    => open
        ,ada_data  => '0'

        ,adb_mux   => open
        ,adb_clock => open
        ,adb_cs    => open
        ,adb_data  => '0'

        ,dab_spi_clock => open
        ,dab_spi_cs    => open
        ,dab_spi_data  => '0'

        ,llc_spi_clock => open
        ,llc_spi_cs    => open
        ,llc_spi_data  => '0'

        ,bus_to_measurements   => init_fpga_interconnect
        ,bus_from_measurements => open
        ,ram_b_in              => ram_b_in);
------------------------------------------------------------------------
------------------------------------------------------------------------
end vunit_simulation;
