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
        system_is_stopped           : boolean;
        fault_has_been_acknowledged : boolean;
        trip_has_been_detected      : boolean;
    end record;
------------------------------------------------------------------------
    type list_of_actions is record
        command_start : boolean;
    end record;
------------------------------------------------------------------------
    procedure create_main_state_machine (
        signal main_state_machine_object : inout main_state_machine_record;
        received_event_is                : in list_of_events);
------------------------------------------------------------------------
end package main_state_machine_pkg;

package body main_state_machine_pkg is
------------------------------------------------------------------------
    procedure create_main_state_machine 
    (
        signal main_state_machine_object : inout main_state_machine_record;
        received_event_is                : in list_of_events
    ) 
    is
        alias system_state is main_state_machine_object.system_states;
    begin
    --------------------------------------------------
        CASE system_state is
            WHEN idle  =>
                if received_event_is.start_has_been_commanded then
                    system_state <= init;
                end if;

            WHEN init  =>
                if received_event_is.dc_link_is_ready then
                    system_state <= run;
                end if;

            WHEN run   =>
                if received_event_is.system_is_running then
                    system_state <= run;
                else
                    system_state <= idle;
                end if;

            WHEN fault =>
                if received_event_is.fault_has_been_acknowledged then
                    system_state <= idle;
                end if;

        end CASE;

    --------------------------------------------------
        if system_state /= fault and received_event_is.system_is_stopped then
            system_state <= idle;
        end if;

    --------------------------------------------------
        if received_event_is.trip_has_been_detected then
            system_state <= fault;
        end if;

    end procedure;
------------------------------------------------------------------------
end package body main_state_machine_pkg;
