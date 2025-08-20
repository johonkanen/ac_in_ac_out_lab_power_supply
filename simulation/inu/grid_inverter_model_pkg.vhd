
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package grid_inverter_model_pkg is

    constant c1    : natural := 0;
    constant l1    : natural := 1;
    constant c2    : natural := 2;
    constant l2    : natural := 3;
    constant c3    : natural := 4;
    constant lpri  : natural := 5;
    constant cdc   : natural := 6;

    function deriv_grid_inverter(states : real_vector; modulation_index : real ; load_current : real; grid_voltage : real) return real_vector;

end package grid_inverter_model_pkg;

package body grid_inverter_model_pkg is

-----------------------------
    function bridge_voltage(
        dc_link_voltage : real
        ;input_voltage : real
        ;inductor_current : real
        ;modulation_index : real := 1.0
    ) return real is
        variable retval : real := 0.0;
    begin

        if modulation_index >= 1.0
        then
            if (modulation_index * dc_link_voltage < input_voltage) or (inductor_current > 0.0)
            then
                retval := abs(input_voltage) - dc_link_voltage * modulation_index;
            end if;
        else
            retval := input_voltage - dc_link_voltage * modulation_index;
        end if;

        return retval;
    end bridge_voltage;
-----------------------------

    constant c1_val          : real := 2.0e-6;
    constant c2_val          : real := 7.0e-6;
    constant rc1             : real := 10.0e-3;
    constant rc2             : real := 10.0e-3;

    constant l1_val          : real := 2.2e-6;
    constant l2_val          : real := 2.2e-6;
    constant Lpri_val        : real := 1.0e-3;
    constant lgrid           : real := 10.0e-6;
    constant dc_link_cap_val : real := 1500.0e-6;

-------------------------------------
    function deriv_grid_inverter(states : real_vector; modulation_index : real ; load_current : real; grid_voltage : real) return real_vector is
        variable l1_voltage      : real := 0.0;
        variable c1_current      : real := 0.0;
        variable l2_voltage      : real := 0.0;
        variable c2_current      : real := 0.0;
        variable lpri_voltage    : real := 0.0;
        variable dc_link_current : real := 0.0;
        variable bridge_current  : real := 0.0;

        variable retval : states'subtype := (others => 0.0);

    begin
        l1_voltage := grid_voltage - states(c1) - rc1*(states(l1) - states(l2));
        c1_current := states(l1) - states(l2);
        l2_voltage := states(c1) - states(c2) - rc1*(states(l1) - states(l2)) - rc2*(states(l2) - states(lpri));
        c2_current := states(l2) - states(lpri);

        lpri_voltage := bridge_voltage(
            dc_link_voltage   => states(cdc)
            ,input_voltage    => states(c2)
            ,inductor_current => states(lpri)
            ,modulation_index => modulation_index
        );

        dc_link_current := (modulation_index * states(lpri) - load_current);

        retval(l1)   := l1_voltage      / l1_val;
        retval(c1)   := c1_current      / c1_val;
        retval(l2)   := l2_voltage      / l2_val;
        retval(c2)   := c2_current      / c2_val;
        retval(lpri) := lpri_voltage    / Lpri_val;
        retval(cdc)  := dc_link_current / dc_link_cap_val;

        return retval;
    end deriv_grid_inverter;
-------------------------------------
end package body grid_inverter_model_pkg;
