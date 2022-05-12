library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package main_state_machine_pkg is
------------------------------------------------------------------------
    type list_of_system_states is (idle, init, run, fault);
------------------------------------------------------------------------
    type main_state_machine_record is record
        system_states : list_of_system_states;
    end record;

    constant init_main_state_machine : main_state_machine_record := (system_states => idle);
------------------------------------------------------------------------
    type list_of_events is record
        start_has_been_commanded    : boolean;
        dc_link_is_ready            : boolean;
        system_is_running           : boolean;
        fault_has_been_acknowledged : boolean;
        trip_has_been_detected      : boolean;
    end record;
------------------------------------------------------------------------
    procedure create_main_state_machine (
        signal main_state_machine_object : inout main_state_machine_record;
        events                           : in list_of_events);
------------------------------------------------------------------------
end package main_state_machine_pkg;

package body main_state_machine_pkg is
------------------------------------------------------------------------
    procedure create_main_state_machine 
    (
        signal main_state_machine_object : inout main_state_machine_record;
        events                           : in list_of_events
    ) 
    is
        alias system_state is main_state_machine_object.system_states;
    begin

        if events.trip_has_been_detected then
            system_state <= fault;
        end if;
    end procedure;

------------------------------------------------------------------------
end package body main_state_machine_pkg;
