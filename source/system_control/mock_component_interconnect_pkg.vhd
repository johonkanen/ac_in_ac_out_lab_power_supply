library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

-- mocked interconnect package
package component_interconnect_pkg is

    type component_interconnect_data_input_group is record
        data_in : std_logic;
    end record;
    
    type component_interconnect_data_output_group is record
        data_out : std_logic;
        trigger_trip : boolean;
        start_is_requested : boolean;
    end record;
    constant init_component_interconnect : component_interconnect_data_output_group := 
    ('0', false, false);

end package component_interconnect_pkg;
