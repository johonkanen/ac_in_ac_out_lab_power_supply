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
    function system_is_initialized (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
    function trip_is_detected (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
    function fault_is_acknowledged (
        component_interconnect_output : component_interconnect_data_output_group)
        return boolean;
------------------------------------------------------------------------
end package system_component_interface_pkg;
