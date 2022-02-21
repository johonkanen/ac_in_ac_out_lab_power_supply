LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_testi is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_testi is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 150;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal clock_divider : integer := 1; 
    signal slow_clock : std_logic := '0';
    signal io : std_logic := '0';
    signal shift_register : std_logic_vector(7 downto 0) := (others => '0');

    signal pwm_counter : integer := 0;
    signal duty : integer range 0 to 31;
    signal previous_value : std_logic := '0';

    function get_counter
    (
        d : integer
    )
    return integer
    is
        variable unsigned_duty : unsigned(5 downto 0);
    begin
        unsigned_duty := to_unsigned(d,6);
        return to_integer(unsigned_duty(5 downto 3));
        
    end get_counter;

    function get_hrpwm
    (
        d : integer
    )
    return integer
    is
        variable unsigned_duty : unsigned(5 downto 0);
    begin
        unsigned_duty := to_unsigned(d,6);
        return to_integer(unsigned_duty(5 downto 4));
        
    end get_hrpwm;

    type seppo is (hovi, raty, taalasmaa);
    signal jee : seppo := seppo'val(1);

    type seppo_int is array (seppo range seppo'right downto seppo'left) of integer;
    signal seppoja : seppo_int := (1,2,3);

begin

    seppoja(hovi) <= 37;

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
    slow_clock_generator : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then

            clock_divider <= clock_divider + 1;
            if clock_divider = 7 then
                clock_divider <= 0;
            end if;

            if clock_divider > 7/2 then
                slow_clock <= '1';
            else
                slow_clock <= '0';
            end if;

        end if; --rising_edge
    end process slow_clock_generator;	
------------------------------------------------------------------------

    stimulus : process(simulator_clock, slow_clock)
        variable io_state : std_logic := '0';

    begin
        if rising_edge(simulator_clock) then
            shift_register <= shift_register(shift_register'left-1 downto 0) & '0';
            io <= shift_register(shift_register'left);
        end if;

        if rising_edge(slow_clock) then
            simulation_counter <= simulation_counter + 1;

            CASE simulation_counter is
                WHEN 4 => duty <= 16;
                WHEN others => --do nothing
            end CASE; --simulation_counter

            pwm_counter <= pwm_counter + 1;
            if pwm_counter = 3 then
                pwm_counter <= 0;
            end if;

            if pwm_counter < get_counter(duty) then
                shift_register <= (others => '1');
                io_state := '1';
            else
                shift_register <= (others => '0');
                io_state := '0';
            end if;

            previous_value <= io_state;
            if io_state = '1' and previous_value = '0' then
                shift_register <= b"0000_1111";
            end if;

            if io_state = '0' and previous_value = '1' then
                shift_register <= b"1111_0000";
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
