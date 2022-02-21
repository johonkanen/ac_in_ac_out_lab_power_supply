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
    signal testi1  : unsigned(31 downto 0) := x"ffff_ffff";
    signal testi2  : unsigned(31 downto 0) := x"ffff_ffff";
    signal result  : unsigned(63 downto 0) := (others => '0');
    signal atest : unsigned(63 downto 0) := (others => '0');

    type long_multiplier_record is record
        process_counter            : integer;
        multiplier_process_counter : integer;
        left                       : unsigned(31 downto 0);
        right                      : unsigned(31 downto 0);
    end record;

    constant init_long_multiplier : long_multiplier_record := (0,0, (others => '0'), (others => '0'));
    signal multiplier_object : long_multiplier_record := init_long_multiplier;

    alias process_counter is multiplier_object.process_counter;
    alias multiplier_process_counter is multiplier_object.multiplier_process_counter;

    signal var1 : unsigned(31 downto 0) := (others => '0');
    signal var2 : unsigned(31 downto 0) := (others => '0');
    signal var3 : unsigned(31 downto 0) := (others => '0');
    signal var4 : unsigned(31 downto 0) := (others => '0');

    signal multiplier_result : unsigned(31 downto 0) := (others => '0');
    signal multiplier_is_ready : boolean := false;


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

                    var4 <= a1*b1;
                    var3 <= a1*b0;
                    var2 <= a0*b1;
                    var1 <= a0*b0;

            -- result2 <= resize(var1*2**16*2**16, 64) + var3*2**16 + var2*2**16 + var4;
            multiplier_is_ready <= false;
            CASE multiplier_process_counter is
                WHEN 0 =>
                    multiplier_result <= a1*b1;
                    multiplier_is_ready <= true;
                    increment(multiplier_process_counter);
                WHEN 1 =>
                    multiplier_result <= a1*b0;
                    multiplier_is_ready <= true;
                    increment(multiplier_process_counter);
                WHEN 2 =>
                    multiplier_result <= a0*b1;
                    multiplier_is_ready <= true;
                    increment(multiplier_process_counter);
                WHEN 3 =>
                    multiplier_result <= a0*b0;
                    multiplier_is_ready <= true;
                    increment(multiplier_process_counter);
                WHEN others => -- do nothing
            end CASE; --multiplier_process_counter

            CASE process_counter is
                WHEN 0 => 
                    if multiplier_is_ready then
                        atest(31 downto 0)   <= multiplier_result;
                        increment(process_counter);
                    end if;

                WHEN 1 => 
                    atest(31+16 downto 16) <= multiplier_result+atest(31 downto 16);
                    increment(process_counter);

                WHEN 2 => 
                    atest(31+16 downto 16) <= multiplier_result+atest(31+16 downto 16);
                    increment(process_counter);

                WHEN 3 => 
                    atest(63 downto 32) <= multiplier_result+atest(31+16 downto 32);
                    increment(process_counter);

                WHEN others =>
            end CASE; --process_counter

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
