LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.NUMERIC_STD.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.pwm_pkg.all;

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
    signal duty : natural range 0 to 2**16-1 := 100;


    constant init_pwm : pwm_record := (false,'0', 0, 100);

    signal pwm : pwm_record := init_pwm;

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

            create_pwm(self => pwm, pwm_out => pwm_out);

            CASE simulation_counter is
                WHEN 1000 => pwm.is_enabled <= true;
                WHEN 15e3 => pwm.duty <= 750;
                WHEN others => --do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	

    carrier <= pwm.carrier;
------------------------------------------------------------------------
end vunit_simulation;
