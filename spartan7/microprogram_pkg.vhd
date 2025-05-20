
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;
    use work.real_to_fixed_pkg.all;

package microprogram_pkg is

    ------------------- microprogram processor implementation -------------------------------
    constant instruction_length : natural := 32;
    constant word_length        : natural := 36;
    constant used_radix         : natural := word_length - 11;
    
    --function to_fixed is new generic_to_fixed 
    --generic map(word_length, used_radix);

    constant ref_subtype : subtype_ref_record := create_ref_subtypes(readports       => 3 , datawidth => word_length , addresswidth => 10);
    constant instr_ref_subtype : subtype_ref_record := create_ref_subtypes(readports => 1 , datawidth => 32          , addresswidth          => 10);

    constant readports : natural := 3;
    constant addresswidth : natural := 7;
    constant datawidth : natural := word_length;

    use work.ram_connector_pkg.all;
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


    constant y    : natural := 50;
    constant u    : natural := 60;
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
           0 => to_fixed(0.0,bit_width => word_length, number_of_fractional_bits => used_radix)

         , 1 => to_fixed(1.0  , word_length , used_radix)
         , 2 => to_fixed(2.0  , word_length , used_radix)
         , 3 => to_fixed(-3.0 , word_length , used_radix)

        , duty             => to_fixed(0.5,word_length, used_radix)
        , inductor_current => to_fixed(0.0,word_length, used_radix)
        , cap_voltage      => to_fixed(0.0,word_length, used_radix)
        , ind_res          => to_fixed(0.9,word_length, used_radix)
        , load             => to_fixed(0.0,word_length, used_radix)
        , current_gain     => to_fixed(sampletime*1.0/2.0e-6,word_length, used_radix)
        , voltage_gain     => to_fixed(sampletime*1.0/3.0e-6,word_length, used_radix)
        , input_voltage    => to_fixed(10.0,word_length, used_radix)
        , inductor_voltage => to_fixed(0.0,word_length, used_radix)

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
        , 28 => op(set_rpt     , 200)
        , 29 => op(neg_mpy_add , inductor_voltage , duty             , cap_voltage      , input_voltage)
        , 30 => op(mpy_sub     , cap_current      , duty             , inductor_current , load)
        , 36 => op(neg_mpy_add , inductor_voltage , ind_res          , inductor_current , inductor_voltage)
        , 37 => op(mpy_add     , cap_voltage      , cap_current      , voltage_gain     , cap_voltage)
        , 40 => op(jump        , 29)
        , 43 => op(mpy_add     , inductor_current , inductor_voltage , current_gain     , inductor_current)

        , others => op(nop));
    ------------------- microprogram processor implementation end ---------------------------


end microprogram_pkg;
----------------------------------------------
