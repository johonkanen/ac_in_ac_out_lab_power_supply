package body system_component_interface_pkg is
------------------------------------------------------------------------
    function run_is_commanded
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return component_interconnect_output.start_is_requested;
        
    end run_is_commanded;
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
    function trip_is_detected
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return component_interconnect_output.trigger_trip;
        
    end trip_is_detected;
------------------------------------------------------------------------
    function fault_is_acknowledged
    (
        component_interconnect_output : component_interconnect_data_output_group
    )
    return boolean
    is
    begin
        return true;

    end fault_is_acknowledged;
------------------------------------------------------------------------

end package body system_component_interface_pkg;
