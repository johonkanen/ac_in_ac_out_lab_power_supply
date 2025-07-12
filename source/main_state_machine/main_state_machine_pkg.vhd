LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package main_state_machine_pkg is

    type t_main_states is (idle, precharge, running, fault);

    type main_state_record is record
        main_state : t_main_states;
    end record;

    constant init_main_state : main_state_record := (main_state => idle);

    procedure generic_main_state_machine
    generic (
        procedure start_precharge is <>
    )(
        signal self : inout main_state_record
        ;start_requested    : in boolean
        ;precharge_ready    : in boolean
        ;fault_detected     : in boolean
        ;fault_acknowledged : in boolean
        ;shutdown_requested : in boolean
    );

    function report_state(self : main_state_record) return natural;

end package main_state_machine_pkg;

package body main_state_machine_pkg is

    procedure generic_main_state_machine
    generic (
        procedure start_precharge is <>
    )(
        signal self : inout main_state_record
        ;start_requested : in boolean
        ;precharge_ready : in boolean
        ;fault_detected : in boolean
        ;fault_acknowledged : in boolean
        ;shutdown_requested : in boolean
    ) is
    begin
        CASE self.main_state is
            WHEN idle =>

                if start_requested
                then
                    start_precharge;
                    self.main_state <= precharge;
                end if;

            WHEN precharge =>

                if precharge_ready
                then
                    self.main_state <= running;
                end if;

            WHEN running =>

            WHEN fault =>
                if fault_acknowledged
                then
                    self.main_state <= idle;
                end if;
        end CASE;

        if shutdown_requested and self.main_state /= fault
        then
            self.main_state <= idle;
        end if;

        if fault_detected
        then
            self.main_state <= fault;
        end if;

        if fault_acknowledged and self.main_state = fault
        then
            self.main_state <= idle;
        end if;

    end generic_main_state_machine;

    function report_state(self : main_state_record) return natural is
    begin
        return t_main_states'pos(self.main_state);
    end report_state;


end package body;
