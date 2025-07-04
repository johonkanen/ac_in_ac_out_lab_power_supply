LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package meas_scaler_pkg is

    type meas_scaler_in_record is record
        conversion_requested : boolean;
        data_in              : signed(39 downto 0) ;
        address              : natural;
    end record;

    type meas_scaler_out_record is record
        data_out             : signed(39 downto 0);
        out_address          : natural            ;
        is_ready             : boolean            ;
    end record;

    procedure init_meas_scaler(signal self_in : out meas_scaler_in_record);
    procedure request_scaler(signal self_in : out meas_scaler_in_record
         ; data : in signed
         ; address : in natural);

    function conversion_is_ready(self_out : meas_scaler_out_record) return boolean;
    function get_converted_meas(self_out : meas_scaler_out_record) return signed;
    function get_converted_address(self_out : meas_scaler_out_record) return natural;

end package meas_scaler_pkg;

package body meas_scaler_pkg is

    procedure init_meas_scaler(signal self_in : out meas_scaler_in_record) is
    begin
        self_in.conversion_requested <= false;
    end init_meas_scaler;

    procedure request_scaler(signal self_in : out meas_scaler_in_record
         ; data : in signed
         ; address : in natural) is
    begin
        self_in.conversion_requested <= true;
        self_in.data_in <= data;
        self_in.address <= address;
    end request_scaler;

    function conversion_is_ready(self_out : meas_scaler_out_record) return boolean is
    begin
        return self_out.is_ready;
    end conversion_is_ready;

    function get_converted_meas(self_out : meas_scaler_out_record) return signed is
    begin
        return self_out.data_out;
    end get_converted_meas;

    function get_converted_address(self_out : meas_scaler_out_record) return natural is
    begin
        return self_out.out_address;
    end get_converted_address;

end package body meas_scaler_pkg;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.dual_port_ram_pkg.all;
    use work.meas_scaler_pkg.all;

entity meas_scaler is
    generic (init_values : work.dual_port_ram_pkg.ram_array
            ;radix : natural := 30);
    port(
        clock     : in std_logic
        ;self_in  : in meas_scaler_in_record
        ;self_out : out meas_scaler_out_record
    );
end meas_scaler;

architecture rtl of meas_scaler is

    constant dp_ram_subtype : dpram_ref_record := 
        create_ref_subtypes(
            datawidth      => init_values(0)'length
            , addresswidth => 10);

    --------------------
    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    --------------------
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;
    --------------------
    type address_array is array(integer range 0 to 15) of natural;
    type data_array is array(integer range 0 to 15) of signed(self_in.data_in'range);
    signal address_pipeline : address_array := (0 => 0, 1 => 1, 2 => 2, others => 15);
    signal data_pipeline : data_array :=(others => (others => '0'));
    constant zero : signed(self_in.data_in'range) := (others => '0');

    constant datawidth : natural := dp_ram_subtype.ram_in.data'length;

    signal a, b, c , cbuf : signed(datawidth-1 downto 0);
    signal mpy_res        : signed(2*datawidth-1 downto 0);
    signal mpy_res2       : signed(2*datawidth-1 downto 0);
    
    signal tessti : natural := 0;

    signal ready_pipeline : std_logic_vector(0 to 15) := (others => '0');

begin
    tessti <= address_pipeline(15);

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

            address_pipeline <= self_in.address & address_pipeline(0 to 14);
            data_pipeline    <= self_in.data_in & data_pipeline(0 to 14);
            ready_pipeline   <= '0' & ready_pipeline(0 to 14);

            if self_in.conversion_requested
            then 
                ready_pipeline(0) <= '1';
                request_data_from_ram(ram_a_in, self_in.address*2);
                request_data_from_ram(ram_b_in, self_in.address*2+1);
            end if;

            if ram_read_is_ready(ram_a_out) 
            then
                a <= resize(data_pipeline(3), datawidth);
                b <= resize(signed(get_ram_data(ram_a_out)), datawidth);
                c <= resize(signed(get_ram_data(ram_b_out)), datawidth);
            end if;

            self_out.out_address <= address_pipeline(6);
            self_out.data_out    <= mpy_res(radix+ram_a_out.data'length-1 downto radix);
            self_out.is_ready    <= ready_pipeline(6) = '1';

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
    use work.meas_scaler_pkg.all;

    constant word_length : natural := 40;

    function to_fixed is new generic_to_fixed generic map(word_length => word_length, used_radix => 29);

    constant init_values : ram_array(0 to 1023)(word_length-1 downto 0) := 
    (
     0 => to_fixed(10.0)
    ,1 => to_fixed(0.5)

    ,2 => to_fixed(10.0)
    ,3 => to_fixed(0.5)

    ,4 => to_fixed(0.001)
    ,5 => to_fixed(0.5)

    ,6 => to_fixed(-0.001)
    ,7 => to_fixed(0.5)

    ,others => (others => '0'));

    signal address_out : natural;
    signal self_in : meas_scaler_in_record;
    signal self_out : meas_scaler_out_record;

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
            init_meas_scaler(self_in);

            CASE simulation_counter is
                WHEN 0 => request_scaler(self_in, signed(to_fixed(10.0)), 0);
                WHEN 1 => request_scaler(self_in, signed(to_fixed(11.1)), 1);
                WHEN 2 => request_scaler(self_in, signed(to_fixed(12.2)), 2);
                WHEN 3 => request_scaler(self_in, signed(to_fixed(13.3)), 3);
                WHEN others => --do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    u_meas_scaler : entity work.meas_scaler
    generic map(init_values)
    port map(
        clock => simulator_clock
        ,self_in
        ,self_out
    );
------------------------------------------------------------------------
end vunit_simulation;
