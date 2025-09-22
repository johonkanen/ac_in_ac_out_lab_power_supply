
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity uproc_test is
    generic ( g_word_length : natural := 40
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
    constant used_radix : natural := 29;
    
    use work.real_to_fixed_pkg.all;
    function to_fixed is new generic_to_fixed 
    generic map(word_length => word_length, used_radix => used_radix);

    use work.microinstruction_pkg.all;

    use work.multi_port_ram_pkg.all;

    constant ref_subtype       : subtype_ref_record := create_ref_subtypes(readports => 3, datawidth => word_length, addresswidth => 10);
    constant instr_ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 1, datawidth => 32, addresswidth => 10);

    signal mc_read_in  : ref_subtype.ram_read_in'subtype;
    signal mc_read_out : ref_subtype.ram_read_out'subtype;
    signal mc_output   : ref_subtype.ram_write_in'subtype;

    use work.ram_connector_pkg.all;

    constant readports    : natural := 3;
    constant addresswidth : natural := 10;
    constant datawidth    : natural := word_length;

    constant ram_connector_ref : ram_connector_record := (
            read_in => (
                0 to readports - 1 => (
                    address        => (0 to addresswidth - 1 => '0'),
                    read_requested => '0'
                )
            )

            ,read_out => (
                0 to readports - 1 => (
                    data          => (datawidth - 1 downto 0 => '0'),
                    data_is_ready => '0'
                )
            ));

    signal ram_connector : ram_connector_ref'subtype;

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
        , 10  => op(mpy_sub,9, 2, 2, 1)
        , 13 => op(program_end)

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

    signal mproc_in  : microprogram_processor_in_record;
    signal mproc_out : microprogram_processor_out_record;

    signal start_counter : natural range 0 to 127 := 0;

    signal simcurrent : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal simvoltage : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);

begin 

    process(clock) is
    begin
        if rising_edge(clock)
        then
            init_bus(bus_from_uproc);
            connect_data_to_address(bus_from_communications , bus_from_uproc , 500 , ext_input(used_radix + 5        downto used_radix+5-31));
            connect_data_to_address(bus_from_communications , bus_from_uproc , 501 , lc_load(used_radix + 5          downto used_radix+5-31));
            connect_data_to_address(bus_from_communications , bus_from_uproc , 502 , lc_duty(used_radix + 5          downto used_radix+5-31));
            connect_data_to_address(bus_from_communications , bus_from_uproc , 503 , lc_input_voltage(used_radix + 5 downto used_radix+5-31));
            connect_data_to_address(bus_from_communications , bus_from_uproc , 504 , simcurrent(used_radix + 5       downto used_radix+5-31));
            connect_data_to_address(bus_from_communications , bus_from_uproc , 505 , simvoltage(used_radix + 5       downto used_radix+5-31));

            start_counter <= start_counter + 1;
            if start_counter > 50
            then
                start_counter <= 0;
            end if;

            init_mproc(mproc_in);
            if start_counter = 0
            then
                calculate(mproc_in, 129);
            end if;

            init_ram_connector(ram_connector);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 120, ext_input);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 121, lc_load);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 122, lc_duty);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 123, lc_input_voltage);
            connect_ram_write_to_address(mc_output , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_output , cap_voltage      , simvoltage);

        end if;
    end process;
-------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_processor
    generic map(g_data_bit_width => word_length,g_used_radix => used_radix, g_program => test_program, g_data => program_data)
    port map(clock, mproc_in, mproc_out, mc_read_in, mc_read_out, mc_output);
-------------------------------------------------------------------------

end v1;
