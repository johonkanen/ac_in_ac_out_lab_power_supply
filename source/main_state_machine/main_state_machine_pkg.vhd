LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package main_state_machine_pkg is

    type t_main_states is (idle, precharge, running, fault);

    type main_state_record is record
        main_state : t_main_states;
    end record;

    constant init_main_state : main_state_record := (main_state => idle);

    procedure create_main_state_machine(signal self : inout main_state_record
        ;start_requested : in boolean
        ;precharge_ready : in boolean
        ;fault_detected : in boolean
        ;fault_acknowledged : in boolean
    );


end package main_state_machine_pkg;

package body main_state_machine_pkg is

    procedure create_main_state_machine(signal self : inout main_state_record
        ;start_requested : in boolean
        ;precharge_ready : in boolean
        ;fault_detected : in boolean
        ;fault_acknowledged : in boolean
    ) is
    begin

        CASE self.main_state is
            WHEN idle =>

                if start_requested
                then
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

        if fault_detected
        then
            self.main_state <= fault;
        end if;

    end create_main_state_machine;

end package body;

------------------------------------
