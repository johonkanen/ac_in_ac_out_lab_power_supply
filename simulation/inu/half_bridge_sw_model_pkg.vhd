LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package buck_sw_model_pkg is

    ------------------------------------------
    type lcr_model_record is record
        l : real;
        c : real;
        i_load : real;
    end record;
    ------------------------------------------
    type sw_states is (hi, lo);
    ------------------------------------------
    function half_bridge_sw_model(
        sw_state : sw_states 
        ; inductor_current : real
        ; dc_link_voltage : real) 
        return real_vector;
    ------------------------------------------
    function deriv_lcr_model (
        lcr : lcr_model_record
        ; sw_state : sw_states
        ; il : real
        ; uc : real
        ; dc_link_voltage : real) 
        return real;
    ------------------------------------------
end package;

package body buck_sw_model_pkg is

    ------------------------------------------
    function half_bridge_sw_model(sw_state : sw_states ; inductor_current : real; dc_link_voltage : real) return real_vector is
        variable hb_voltage : real;
        variable dc_link_current : real;
    begin

        CASE sw_state is
            WHEN hi =>
                hb_voltage      := dc_link_voltage;
                dc_link_current := inductor_current;
            WHEN lo =>
                hb_voltage      := 0.0;
                dc_link_current := 0.0;
        end CASE;

        return (hb_voltage, dc_link_current);

    end half_bridge_sw_model;
    ------------------------------------
    function deriv_lcr_model (
        lcr               : lcr_model_record
        ; sw_state        : sw_states
        ; il : real
        ; uc : real
        ; dc_link_voltage : real) return real is
        variable retval : real;
        variable hb_voltage_and_current : real_vector(0 to 1) := (0.0, 0.0);
    begin

        hb_voltage_and_current := half_bridge_sw_model(sw_state , il, dc_link_voltage);
        retval := (hb_voltage_and_current(0) - il * 0.01 - uc)  * (1.0/lcr.l);

        return retval;
    end deriv_lcr_model;
    ------------------------------------------

end package body;

