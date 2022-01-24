library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.component_interconnect_pkg.all;

package system_component_interface_pkg is
------------------------------------------------------------------------
    function run_is_commanded (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
    procedure request_init (
        signal component_interconnect_input : out component_interconnect_data_input_group);
------------------------------------------------------------------------
    function system_is_initialized (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
    function trip_has_detected (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
    function fault_has_been_acknowledged (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;

end package system_component_interface_pkg;

package body system_component_interface_pkg is
------------------------------------------------------------------------
    function run_is_commanded
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return true;
        
    end run_is_commanded;
------------------------------------------------------------------------
    procedure request_init
    (
        signal component_interconnect_input : out component_interconnect_data_input_group
    ) is
    begin
        
    end request_init;
------------------------------------------------------------------------
    function system_is_initialized
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return true;
    end system_is_initialized;
------------------------------------------------------------------------
    procedure request_power_down
    (
        signal component_interconnect_input : out component_interconnect_data_input_group
    ) is
    begin
        
    end request_power_down;
------------------------------------------------------------------------
    function trip_has_detected
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return true;
        
    end trip_has_detected;
------------------------------------------------------------------------
    function fault_has_been_acknowledged
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return true;
    end fault_has_been_acknowledged;
------------------------------------------------------------------------

end package body system_component_interface_pkg;
