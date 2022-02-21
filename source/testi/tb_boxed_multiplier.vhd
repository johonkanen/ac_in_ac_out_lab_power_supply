LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

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
    signal testi1  : unsigned(31 downto 0) := x"abcdef01";
    signal testi2  : unsigned(31 downto 0) := x"07f1_1111";
    signal result  : unsigned(63 downto 0) := (others => '0');
    signal result2 : unsigned(63 downto 0) := (others => '0');

    signal process_counter : integer := 0;

    signal var1 : unsigned(31 downto 0) := (others => '0');
    signal var2 : unsigned(31 downto 0) := (others => '0');
    signal var3 : unsigned(31 downto 0) := (others => '0');
    signal var4 : unsigned(31 downto 0) := (others => '0');

    procedure increment
    (
        signal counter : inout integer
    ) is
    begin
        counter <= counter +  1;
    end increment;

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

        variable a0 : unsigned(15 downto 0) := (others => '0');
        variable a1 : unsigned(15 downto 0) := (others => '0');

        variable b0 : unsigned(15 downto 0) := (others => '0');
        variable b1 : unsigned(15 downto 0) := (others => '0');

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            a1 := testi1(15 downto 0);
            a0 := testi1(31 downto 16);

            b1 := testi2(15 downto 0);
            b0 := testi2(31 downto 16);

            result  <= testi1 * testi2;

            -- result2 <= resize(var1*2**16*2**16, 64) + var3*2**16 + var2*2**16 + var4;
            CASE process_counter is
                WHEN 0 => 
                    var1 <= a0*b0;
                    var2 <= a0*b1;
                    var3 <= a1*b0;
                    var4 <= a1*b1;
                    increment(process_counter);

                WHEN 1 => 
                    result2(63 downto 32) <= var1;
                    increment(process_counter);

                WHEN 2 => 
                    result2 <= result2 + (var2 + var3)*2**16;
                    increment(process_counter);

                WHEN 3 => 
                    result2 <= result2 + var4;
                    increment(process_counter);

                WHEN others =>
            end CASE; --process_counter

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
