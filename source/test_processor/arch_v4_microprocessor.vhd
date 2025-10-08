-- library ieee;
--     use ieee.std_logic_1164.all;
--     use ieee.numeric_std.all;
--
--     use work.fpga_interconnect_pkg.all;
--
-- entity uproc_test is
--     generic ( g_word_length : natural := 40
--             );
--     port ( 
--         clock : in std_logic 
--         ; bus_from_communications : in fpga_interconnect_record
--         ; bus_from_uproc          : out fpga_interconnect_record
--         ; measurement             : in std_logic_vector(31 downto 0) := (others => '0')
--     );
-- end entity uproc_test;


architecture v4 of uproc_test is

    use work.microprogram_processor_pkg.all;
    use work.microinstruction_pkg.all;
    -- simulation specific signals ----
    constant instruction_length : natural := 32;
    constant word_length        : natural := 32;
    constant used_radix         : natural := 20;

    --
    use work.multi_port_ram_pkg.all;

    constant ref_subtype       : subtype_ref_record := 
        create_ref_subtypes(readports => 3 
        , datawidth => word_length        
        , addresswidth => 10);

    constant instr_ref_subtype : subtype_ref_record := 
    create_ref_subtypes(readports => 1 
    , datawidth => instruction_length 
    , addresswidth => 10);

    signal mc_output   : ref_subtype.ram_write_in'subtype;
    signal mc_write_in : ref_subtype.ram_write_in'subtype := ref_subtype.ram_write_in;

    signal mproc_in     : microprogram_processor_in_record;
    signal mproc_out    : microprogram_processor_out_record;

    use work.instruction_pkg.all;

    constant instruction_in_ref : instruction_in_record := (
        instr_ram_read_out => instr_ref_subtype.ram_read_out
        ,data_read_out     => ref_subtype.ram_read_out
        ,instr_pipeline    => (0 to 12 => op(nop))
        );

    constant instruction_out_ref : instruction_out_record := (
        data_read_in  => ref_subtype.ram_read_in
        ,ram_write_in => ref_subtype.ram_write_in
        );

    signal addsub_in  : instruction_in_ref'subtype  := instruction_in_ref;
    signal addsub_out : instruction_out_ref'subtype := instruction_out_ref;

    ----

    use work.float_to_real_conversions_pkg.all;
    use work.float_typedefs_generic_pkg.all;

    constant load             : natural := 121;
    constant duty             : natural := 122;
    constant input_voltage    : natural := 123;

    constant inductor_current : natural := 22;
    constant cap_voltage      : natural := 23;
    constant ind_res          : natural := 24;
    constant current_gain     : natural := 26;
    constant voltage_gain     : natural := 27;
    constant inductor_voltage : natural := 29;
    constant cap_current      : natural := 31;

    constant test1 : natural := 10;
    constant test2 : natural := 30;
    constant test3 : natural := 40;

    constant sampletime : real := 0.7e-6;

    function to_float(a : real) return std_logic_vector is
        use ieee.float_pkg.all;
    begin
        return to_slv(to_float(a, float32'high));
    end to_float;

    constant program_data : work.dual_port_ram_pkg.ram_array(0 to ref_subtype.address_high)(ref_subtype.data'range) := (
           0 => to_float(0.0)
        ,  1 => to_float(1.0)
        ,  2 => to_float(0.0)
        ,  3 => to_float(-3.0)
        ,  test1 => to_float(0.0)
        ,  11 => to_float(1.0)
        ,  12 => to_float(0.0)
        ,  13 => to_float(0.01)
        ,  14 => to_float(0.01)
        ,  31 => to_float(-1.0)
        ,  34 => to_float(0.005)
        , 4 => to_float(4.0)
        , 5 => to_float(5.0)
        , 6 => to_float(6.0)
        , 7 => to_float(7.0)
        , 8 => to_float(8.0)
        , 9 => to_float(9.0)
        , 41 => to_float(1.0)
        , 42 => to_float(2.0)
        , 43 => to_float(3.0)
        , 44 => to_float(0.001)

        , duty             => to_float(0.8)
        , inductor_current => to_float(0.0)
        , cap_voltage      => to_float(12.0)
        , ind_res          => to_float(0.8)
        , load             => to_float(0.0)
        , current_gain     => to_float(sampletime*1.0/3.0e-6)
        , voltage_gain     => to_float(sampletime*1.0/3.0e-6)
        , input_voltage    => to_float(20.0)
        , inductor_voltage => to_float(0.0)

        , 51   => to_float(-2.0)
        , 52   => to_float(0.1235)
        , 53   => to_float(2.0)
        , 54   => to_float(10.0e6)
        , 55   => to_float(1.0)

        , others => (others => '0')
    );

    constant test_program : work.dual_port_ram_pkg.ram_array(0 to instr_ref_subtype.address_high)(instr_ref_subtype.data'range) := (
        0 => op(nop)

        -- y = y + (u - y ) * g
        -- temp1 = reg11*(-1.0) - y
        -- temp2 = reg11*g + y
        -- y =  1*0 + reg11
        ----

        ,25 => op(neg_mpy_add , 33    , test2 , 1  , 31)    -- y - u
        ,39 => op(mpy_add     , 35    , 33    , 34 , test2) -- (u-y)*g + y
        ,52 => op(mpy_add     , test2 , 1     , 2  , 35)    -- (u-y)*g + y

        ,27 => op(neg_mpy_add , 13    , test1 , 1  , 11)    -- y - u
        ,41 => op(mpy_add     , 15    , 13    , 14 , test1) -- (u-y)*g + y
        ,54 => op(mpy_add     , test1 , 1     , 2  , 15)    -- (u-y)*g + y

        ,55 => op(program_end)
        ----

        ,100 => op(neg_mpy_add , 13    , test1 , 1  , 11) -- u - y
        ,113 => op(mpy_add     , test1 , 13 , 14 , test1) -- (u-y)*g + y

        ,101 => op(neg_mpy_add , 33    , test2 , 1  , 31) -- u - y
        ,114 => op(mpy_add     , test2 , 33 , 34 , test2) -- (u-y)*g + y

        ,102 => op(neg_mpy_add , 43    , test3 , 1  , 41) -- u - y
        ,115 => op(mpy_add     , test3 , 43 , 44 , test3) -- (u-y)*g + y
        ,118 => op(program_end)

        -- lc filter
        -- equation:
        -- didt = input_voltage - duty*dc_link - i*rl
        -- dudt = i*duty - iload

        -- u = u + dudt*h/c
        -- i = i + didt*h/c
        , 129 => op(neg_mpy_add , inductor_voltage , duty             , cap_voltage      , input_voltage)
        , 130 => op(mpy_sub     , cap_current      , duty             , inductor_current , load)
        , 143 => op(neg_mpy_add , inductor_voltage , ind_res          , inductor_current , inductor_voltage)
        , 144 => op(mpy_add     , cap_voltage      , cap_current      , voltage_gain     , cap_voltage)
        , 158 => op(mpy_add     , inductor_current , inductor_voltage , current_gain     , inductor_current)
        , 159 => op(program_end)

        , others => op(nop));


        signal start_counter : natural range 0 to 2**16-1    := 0;
        signal simvoltage    : std_logic_vector(31 downto 0) := (others => '0');
        signal simcurrent    : std_logic_vector(31 downto 0) := (others => '0');
        signal testdata      : std_logic_vector(31 downto 0) := (others => '0');
        signal testdata2     : std_logic_vector(31 downto 0) := (others => '0');
        signal testdata3     : std_logic_vector(31 downto 0) := (others => '0');

        signal enable_calculation : std_logic_vector(31 downto 0) := (others => '0');
        signal start_address : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(25,32));


begin 

    process(clock) is

        use work.ram_connector_pkg.generic_connect_ram_write_to_address;

        use ieee.float_pkg.all;

        impure function convert(data_in : std_logic_vector) return std_logic_vector is
            variable retval : std_logic_vector(31 downto 0);
        begin
            for i in retval'range loop
                retval(i) := data_in(31-i);
            end loop;

            return retval;
        end convert;

        procedure connect_ram_write_to_address is new generic_connect_ram_write_to_address 
        generic map(return_type => std_logic_vector, conv => convert);

    begin
        if rising_edge(clock)
        then
            init_mproc(mproc_in);
            init_mp_write(mc_write_in);

            start_counter <= start_counter + 1;
            if start_counter > 1000
            then
                start_counter <= 0;
            end if;

            init_mproc(mproc_in);
            if start_counter = 0 and enable_calculation(0) = '1'
            then
                calculate(mproc_in, to_integer(signed(start_address)));
            end if;

            connect_ram_write_to_address(mc_output , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_output , cap_voltage      , simvoltage);
            connect_ram_write_to_address(mc_output , test1            , testdata);
            connect_ram_write_to_address(mc_output , test2            , testdata2);
            connect_ram_write_to_address(mc_output , test3            , testdata3);

            init_bus(bus_from_uproc);
            connect_read_only_data_to_address(bus_from_communications, bus_from_uproc, 700, simcurrent);
            connect_read_only_data_to_address(bus_from_communications, bus_from_uproc, 701, simvoltage);
            connect_read_only_data_to_address(bus_from_communications, bus_from_uproc, 702, testdata);
            connect_read_only_data_to_address(bus_from_communications, bus_from_uproc, 703, testdata2);
            connect_read_only_data_to_address(bus_from_communications, bus_from_uproc, 704, testdata3);
            connect_data_to_address(bus_from_communications, bus_from_uproc, 699, enable_calculation);
            connect_data_to_address(bus_from_communications, bus_from_uproc, 698, start_address);

            if write_is_requested_to_address_range(bus_from_communications, 3000, 3127)
            then
                write_data_to_ram(mc_write_in, get_address(bus_from_communications) - 3000, 
                get_slv_data(bus_from_communications));
            end if;

        end if;
    end process;
------------------------------------------------------------------------
------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_controller
    generic map(g_program => test_program, g_data => program_data, g_data_bit_width => word_length)
    port map(clock
    ,mproc_in
    ,mproc_out
    ,mc_output
    ,mc_write_in
    ,instruction_in  => addsub_in
    ,instruction_out => addsub_out);
------------------------------------------------------------------------
    u_float_mult_add : entity work.instruction(float_mult_add)
    generic map(g_option => "agilex", g_instruction_delay => 3)
    port map(clock 
    ,addsub_in
    ,addsub_out);
------------------------------------------------------------------------
end v4;
