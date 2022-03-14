library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.sincos_pkg.all;

package example_pkg is
------------------------------------------------------------------------
    type example_record is record
        multiplier : multiplier_record;
        sincos : sincos_record;
    end record;

    constant init_example : example_record := (multiplier => init_multiplier, sincos => init_sincos);
------------------------------------------------------------------------
    procedure create_example (
        signal example_object : inout example_record);
------------------------------------------------------------------------
    procedure request_example (
        signal example_object : inout example_record; data : in integer);
------------------------------------------------------------------------
    function example_is_ready (example_object : example_record)
        return boolean;
------------------------------------------------------------------------
    function get_data ( example_object : example_record)
        return integer;
------------------------------------------------------------------------
end package example_pkg;

package body example_pkg is
------------------------------------------------------------------------
    procedure create_example 
    (
        signal example_object : inout example_record
    ) 
    is
    begin
        create_multiplier(example_object.multiplier);
        create_sincos(example_object.multiplier, example_object.sincos);
    end procedure;

------------------------------------------------------------------------
    procedure request_example
    (
        signal example_object : inout example_record;
        data : in integer
    ) is
    begin
        request_sincos(example_object.sincos, data);
        
    end request_example;

------------------------------------------------------------------------
    function example_is_ready
    (
        example_object : example_record
    )
    return boolean
    is
    begin
        return sincos_is_ready(example_object.sincos);
    end example_is_ready;

------------------------------------------------------------------------
    function get_data
    (
        example_object : example_record
    )
    return integer
    is
    begin
        return get_sine(example_object.sincos);
    end get_data;
------------------------------------------------------------------------
end package body example_pkg;
