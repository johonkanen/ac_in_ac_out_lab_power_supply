LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

library math_library_22x22;
    use math_library_22x22.multiplier_pkg.all;
    use math_library_22x22.lcr_filter_model_pkg.all;

entity grid_inverter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of grid_inverter_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant max_voltage : real := 1500.0;
    constant voltage_transform_ratio : real := (max_voltage/2.0**21);
    constant real_to_int_voltage_ratio : real := (2.0**21/max_voltage);

    ----
    function real_voltage
    (
        int_voltage : integer
    )
    return real is
    begin

        return real(int_voltage) * voltage_transform_ratio;
    end real_voltage;

    ----
    function int_voltage
    (
        real_volts : real
    )
    return integer is
    begin
        return integer(real_volts*real_to_int_voltage_ratio);
    end int_voltage;
    ----
    function capacitance_is
    (
        capacitance_value : real
    )
    return integer
    is
    begin
        return integer(capacitance_value * 1.0e6);
    end capacitance_is;
    ----
    function inductance_is
    (
        inductor_value : real
    )
    return integer
    is
    begin
        return integer(inductor_value * 1.0e6);
    end inductance_is;
    ----

    signal lcr_model  : lcr_model_record  := init_lcr_model_integrator_gains(inductance_is(3000.0e-6), capacitance_is(200.0e-6));
    signal multiplier : multiplier_record := init_multiplier;
    signal output_voltage : real := 0.0;
    signal input_voltage : real := 400.0;

    signal load_current : real := 0.0;


begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(abs(output_voltage - input_voltage) < 50.0, "error in input and output voltages too high");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier);
            create_test_lcr_filter(
                hw_multiplier     => multiplier,
                lcr_filter_object => lcr_model,
                load_current      => get_capacitor_voltage(lcr_model)/128,
                u_in              => int_voltage(input_voltage));

        if lcr_filter_calculation_is_ready(lcr_model) or simulation_counter = 0 then
            request_lcr_filter_calculation(lcr_model);
        end if;

        output_voltage <= real_voltage(get_capacitor_voltage(lcr_model));
        load_current   <= real_voltage(get_capacitor_voltage(lcr_model)) / 1.0;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
