
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity inu_pwm_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of inu_pwm_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 8.3333333 ns;
    constant simtime_in_clocks : integer := 48e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal pwm_out : std_logic := '0';
    signal carrier : natural range 0 to 2**16-1 := 0;
    signal duty : natural := 100;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            carrier <= carrier + 1;
            if carrier > 5999 then
                carrier <= 0;
            end if;

            if carrier > (5999/2 - duty/2) then
                pwm_out <= '1';
            end if;

            if carrier > (5999/2 + duty/2) then
                pwm_out <= '0';
            end if;

            if simulation_counter = 15e3 then
                duty <= 750;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
