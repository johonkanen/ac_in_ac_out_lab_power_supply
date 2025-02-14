LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package sw_model_generic_pkg is
    generic(package event_pkg is new work.sort_generic_pkg generic map(<>));
    use event_pkg.all;

    type sw_states is (hi, lo);
    ----------------------------------
    type buck_sw_model_record is record
        sw_state       : sw_states;
        next_sw_state  : sw_states;
        was_updated    : boolean;
        t_sw           : real;
        duty           : real;
    end record;

    ----------------------------------
    procedure update(variable self : inout buck_sw_model_record; sim_event : inout event_record; step_length : in real);
    ----------------------------------
    function get_modulated(sw_state : sw_states; current_or_voltage : real) return real;
    ------------------------------------------
end package sw_model_generic_pkg;

package body sw_model_generic_pkg is

    ----------------------------------
    procedure update(variable self : inout buck_sw_model_record; sim_event : inout event_record; step_length : in real) is
    begin

        if self.was_updated then
            self.was_updated := false;
        end if;
        
        sim_event.time_until_event := sim_event.time_until_event - step_length;

        if (sim_event.time_until_event) <= 1.0e-16 then
            self.was_updated := true;
            self.sw_state := self.next_sw_state;
            case self.sw_state is
                WHEN hi => 
                    sim_event.time_until_event := self.t_sw * self.duty;
                    self.next_sw_state := lo;
                WHEN lo => 
                    sim_event.time_until_event := self.t_sw * (1.0-self.duty);
                    self.next_sw_state := hi;
            end CASE;
        end if;
    end update;
    ------------------------------------
    function get_modulated(sw_state : sw_states; current_or_voltage : real) return real is
        variable retval : real;
    begin
        CASE sw_state is
            WHEN hi =>
                retval := current_or_voltage;
            WHEN lo =>
                retval := 0.0;
        end CASE;

        return retval;
    end get_modulated;


end package body sw_model_generic_pkg;
