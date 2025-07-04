LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.dual_port_ram_pkg.all;

entity meas_scaler is
    generic (init_values : work.dual_port_ram_pkg.ram_array
            ;radix : natural := 30);
    port(
        clock                 : in std_logic
        ;conversion_requested : in boolean
        ;data_in              : in signed(15 downto 0)
        ;address              : in natural
        ;data_out             : out signed(39 downto 0)
        ;out_address          : out natural
        ;is_ready             : out boolean
    );
end meas_scaler;

architecture rtl of meas_scaler is

    constant dp_ram_subtype : dpram_ref_record := 
        create_ref_subtypes(
            datawidth      => init_values(0)'length
            , addresswidth => 10);

    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    --------------------
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;
    --------------------
    type instruction_array is array(integer range 0 to 15) of natural;
    type data_array is array(integer range 0 to 15) of signed(data_in'range);
    signal instruction_pipeline : instruction_array := (0 => 0, 1 => 1, 2 => 2, others => 15);
    signal data_pipeline : data_array :=(others => (others => '0'));
    constant zero : signed(15 downto 0) := (others => '0');

    constant datawidth : natural := dp_ram_subtype.ram_in.data'length;

    signal a, b, c , cbuf : signed(datawidth-1 downto 0);
    signal mpy_res        : signed(2*datawidth-1 downto 0);
    signal mpy_res2       : signed(2*datawidth-1 downto 0);
    
    signal tessti : natural := 0;

begin
    tessti <= instruction_pipeline(15);

    process(clock)
    begin
        if rising_edge(clock) then
            ---------------
            mpy_res2 <= a * b;
            cbuf     <= c;
            mpy_res  <= mpy_res2 + shift_left(resize(cbuf , mpy_res'length), radix) ;
            ---------------
            init_ram(ram_a_in);
            init_ram(ram_b_in);

            instruction_pipeline <= address & instruction_pipeline(0 to 14);
            data_pipeline        <= data_in & data_pipeline(0 to 14);

            if conversion_requested
            then 
                request_data_from_ram(ram_a_in, address/2);
                request_data_from_ram(ram_b_in, address/2+1);
            end if;

            if ram_read_is_ready(ram_a_out) 
            then
                a <= resize(data_pipeline(3), datawidth);
                b <= resize(signed(get_ram_data(ram_a_out)), datawidth);
                c <= resize(signed(get_ram_data(ram_b_out)), datawidth);
            end if;

            

        end if; -- rising_edge
    end process;

    u_dpram : entity work.dual_port_ram
    generic map(dp_ram_subtype, init_values)
    port map(
    clock
    , ram_a_in   
    , ram_a_out  
    --------------
    , ram_b_in  
    , ram_b_out);
--------------------------------------------
end rtl;

--------------------------------------------
--------------------------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity measurement_scaling_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of measurement_scaling_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    signal simulator_clock : std_logic := '0';
    signal simulation_counter : natural := 0;

    use work.dual_port_ram_pkg.all;
    use work.real_to_fixed_pkg.all;

    constant word_length : natural := 40;

    function to_fixed is new generic_to_fixed generic map(word_length => word_length, used_radix => 29);

    constant init_values : ram_array(0 to 1023)(word_length-1 downto 0) := 
    (
     0 => to_fixed(10.0)
    ,1 => to_fixed(0.5)

    ,2 => to_fixed(10.0)
    ,3 => to_fixed(0.5)

    ,others => (others => '0'));

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
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    u_meas_scaler : entity work.meas_scaler
    generic map(init_values)
    port map(
        clock => simulator_clock
        ,conversion_requested => true
        ,data_in              => to_fixed(500.0, 16, 0)
        ,address              => 15
    );
------------------------------------------------------------------------
end vunit_simulation;
