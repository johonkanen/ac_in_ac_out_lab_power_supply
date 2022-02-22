LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.long_multiplier_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_boxed_multiplier is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_boxed_multiplier is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal testi1  : unsigned(31 downto 0) := x"ff0f_ffff";
    signal testi2  : unsigned(31 downto 0) := x"ff0f_f0ff";
    signal result  : unsigned(63 downto 0) := (others => '0');
    signal atest : unsigned(63 downto 0)   := (others => '0');

    signal multiplier_object : long_multiplier_record := init_long_multiplier;

    alias process_counter is multiplier_object.process_counter;
    alias multiplier_process_counter is multiplier_object.multiplier_process_counter;

    signal multiplier_result : unsigned(31 downto 0) := (others => '0');
    signal multiplier_is_ready : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            result  <= testi1 * testi2;

            create_long_multiplier(multiplier_object);

            if simulation_counter = 0 then
                request_long_multiplier(multiplier_object, testi1, testi2);
            end if;

            if long_multiplier_is_ready(multiplier_object) then
                atest <= get_multiplier_result(multiplier_object)-result;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
