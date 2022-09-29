LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.aux_pwm_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;


entity tb_aux_pwm is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_aux_pwm is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 48e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----


    signal aux_pwm : aux_pwm_record := init_aux_pwm;
    signal pwm_out : std_logic := '0';

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
            create_aux_pwm(aux_pwm);

            if simulation_counter = 50 then
                start_aux_pwm(aux_pwm);
            end if; 

            aux_pwm.duty_ratio <= 75;
            pwm_out <= aux_pwm.pwm_out;
            aux_pwm.pwm_is_requested <= true;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
