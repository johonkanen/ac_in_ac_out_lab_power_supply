library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

package main_state_machine_pkg is
------------------------------------------------------------------------
    type list_of_system_states is (idle, init, run, fault);
------------------------------------------------------------------------
    type main_state_machine_record is record
        main_state_machine_is_done : boolean;
        main_state_machine_is_requested : boolean;
        system_states : list_of_system_states;
    end record;

    constant init_main_state_machine : main_state_machine_record := (false, false, idle);
------------------------------------------------------------------------
    type list_of_events is record
        dc_link_is_ready       : boolean;
        system_is_running      : boolean;
        trip_has_been_detected : boolean;
    end record;
------------------------------------------------------------------------
    procedure create_main_state_machine (
        signal main_state_machine_object : inout main_state_machine_record;
        bus_in                           : in fpga_interconnect_record;
        signal bus_out                   : out fpga_interconnect_record;
        events                           : in list_of_events);
------------------------------------------------------------------------
    procedure request_main_state_machine (
        signal main_state_machine_object : out main_state_machine_record);
------------------------------------------------------------------------
    function main_state_machine_is_ready (main_state_machine_object : main_state_machine_record)
        return boolean;
------------------------------------------------------------------------
end package main_state_machine_pkg;

package body main_state_machine_pkg is
------------------------------------------------------------------------
    procedure create_main_state_machine 
    (
        signal main_state_machine_object : inout main_state_machine_record;
        bus_in                           : in fpga_interconnect_record;
        signal bus_out                   : out fpga_interconnect_record;
        events                           : in list_of_events
    ) 
    is
        alias main_state_machine_is_requested is main_state_machine_object.main_state_machine_is_requested;
        alias main_state_machine_is_done is main_state_machine_object.main_state_machine_is_done;
    begin
        main_state_machine_is_requested <= false;
        if main_state_machine_is_requested then
            main_state_machine_is_done <= true;
        else
            main_state_machine_is_done <= false;
        end if;
    end procedure;

------------------------------------------------------------------------
    procedure request_main_state_machine
    (
        signal main_state_machine_object : out main_state_machine_record
    ) is
    begin
        main_state_machine_object.main_state_machine_is_requested <= true;
        
    end request_main_state_machine;

------------------------------------------------------------------------
    function main_state_machine_is_ready
    (
        main_state_machine_object : main_state_machine_record
    )
    return boolean
    is
    begin
        return main_state_machine_object.main_state_machine_is_done;
    end main_state_machine_is_ready;

------------------------------------------------------------------------
end package body main_state_machine_pkg;
