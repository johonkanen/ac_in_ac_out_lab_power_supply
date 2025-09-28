library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity uproc_test is
    generic ( g_word_length : natural := 32
            );
    port ( 
        clock : in std_logic 
        ; bus_from_communications : in fpga_interconnect_record
        ; bus_from_uproc          : out fpga_interconnect_record
        ; measurement             : in std_logic_vector(31 downto 0) := (others => '0')
    );
end entity uproc_test;

architecture v1 of uproc_test is

    constant instruction_length : natural := 32;
    constant word_length : natural := g_word_length;
    constant used_radix : natural := 24;
    
    use work.real_to_fixed_pkg.all;
    function to_fixed is new generic_to_fixed 
    generic map(word_length => word_length, used_radix => used_radix);

    use work.microinstruction_pkg.all;
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

    use work.microprogram_processor_pkg.all;
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
    constant y    : natural := 50;
    constant u    : natural := 60;
    constant uext : natural := 120;
    constant g    : natural := 70;

    constant load             : natural := 121;
    constant duty             : natural := 122;
    constant input_voltage    : natural := 123;

    constant inductor_current : natural := 22;
    constant cap_voltage      : natural := 23;
    constant ind_res          : natural := 24;
    constant current_gain     : natural := 26;
    constant voltage_gain     : natural := 27;
    constant inductor_voltage : natural := 29;
    constant rxi              : natural := 30;
    constant cap_current      : natural := 31;

    constant sampletime : real := 1.0e-6;

    constant program_data : work.dual_port_ram_pkg.ram_array(0 to ref_subtype.address_high)(ref_subtype.data'range) := (
           0 => to_fixed(0.0)
        ,  1 => to_fixed(1.0)
        ,  2 => to_fixed(2.0)
        ,  3 => to_fixed(-3.0)

        , duty             => to_fixed(0.5)
        , inductor_current => to_fixed(0.0)
        , cap_voltage      => to_fixed(0.0)
        , ind_res          => to_fixed(0.9)
        , load             => to_fixed(0.0)
        , current_gain     => to_fixed(sampletime*1.0/2.0e-6)
        , voltage_gain     => to_fixed(sampletime*1.0/3.0e-6)
        , input_voltage    => to_fixed(10.0)
        , inductor_voltage => to_fixed(0.0)

        , others => (others => '0')
    );

    constant test_program : work.dual_port_ram_pkg.ram_array(0 to instr_ref_subtype.address_high)(instr_ref_subtype.data'range) := (
        6    => sub(5, 1, 1)
        , 7  => add(6, 1, 1)
        , 8  => mpy(7, 2, 2)
        , 9  => op(mpy_add,8, 2, 2, 1)
        , 10 => op(mpy_sub,9, 2, 2, 1)
        , 13 => op(program_end)

        , 20 => op(lp_filter , 20 , 21 , 22 , 23)
        , 21 => op(lp_filter , 30 , 31 , 32 , 33)
        , 22 => op(lp_filter , 40 , 41 , 42 , 43)
        , 23 => op(lp_filter , 50 , 51 , 52 , 53)

        -- lc filter
        , 129 => op(neg_mpy_add , inductor_voltage , duty             , cap_voltage      , input_voltage)
        , 130 => op(mpy_sub     , cap_current      , duty             , inductor_current , load)
        , 136 => op(neg_mpy_add , inductor_voltage , ind_res          , inductor_current , inductor_voltage)
        , 137 => op(mpy_add     , cap_voltage      , cap_current      , voltage_gain     , cap_voltage)
        , 143 => op(mpy_add     , inductor_current , inductor_voltage , current_gain     , inductor_current)
        , 144 => op(program_end)

        , others => op(nop));

    ----
    signal ext_input : std_logic_vector(word_length-1 downto 0) := to_fixed(-22.351);

    signal current : real := 0.0;
    signal voltage : real := 0.0;

    signal lc_load : std_logic_vector(word_length-1 downto 0)          := to_fixed(1.0);
    signal lc_duty : std_logic_vector(word_length-1 downto 0)          := to_fixed(0.5);
    signal lc_input_voltage : std_logic_vector(word_length-1 downto 0) := to_fixed(10.0);
    use work.microprogram_processor_pkg.all;

    signal start_counter : natural range 0 to 127 := 0;

    signal simcurrent : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal simvoltage : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal start_address : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(129,32));

begin 

    process(clock) is

        use work.ram_connector_pkg.generic_connect_ram_write_to_address;

        function convert(data_in : std_logic_vector) return std_logic_vector is
            variable retval : std_logic_vector(31 downto 0 );
        begin
            for i in retval'range loop
                retval(i) := data_in(i);
            end loop;
            return retval;
        end convert;

        procedure connect_ram_write_to_address is new generic_connect_ram_write_to_address 
        generic map(return_type => std_logic_vector, conv => convert);

    begin
        if rising_edge(clock)
        then
            init_bus(bus_from_uproc);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 500 , ext_input       /*( used_radix + 5        downto used_radix+5-31   )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 501 , lc_load         /*( used_radix + 5          downto used_radix+5-31 )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 502 , lc_duty         /*( used_radix + 5          downto used_radix+5-31 )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 503 , lc_input_voltage/*( used_radix + 5 downto used_radix+5-31          )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 504 , simcurrent      /*( used_radix + 5       downto used_radix+5-31    )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 505 , simvoltage      /*( used_radix + 5       downto used_radix+5-31    )*/);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 398 , start_address);

            start_counter <= start_counter + 1;
            if start_counter > 100
            then
                start_counter <= 0;
            end if;

            init_mproc(mproc_in);
            if start_counter = 0
            then
                calculate(mproc_in, to_integer(signed(start_address)));
            end if;

            if write_is_requested_to_address_range(bus_from_communications, 2000, 2127)
            then
                write_data_to_ram(mc_write_in
                , get_address(bus_from_communications) - 2000
                , get_slv_data(bus_from_communications));

            end if;
            connect_ram_write_to_address(mc_output , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_output , cap_voltage      , simvoltage);

        end if;
    end process;
-------------------------------------------------------------------------
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
    u_fixed_mult_add : entity work.instruction(fixed_mult_add)
    generic map(radix => 20)
    port map(clock 
    ,addsub_in
    ,addsub_out);
------------------------------------------------------------------------

end v1;
