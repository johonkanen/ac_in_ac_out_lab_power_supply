LIBRARY ieee, std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

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
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    -- these are to be fed from a package
    constant max_voltage         : real    := 1500.0;
    constant word_length_in_bits : integer := 22;
    constant word_length         : integer := word_length_in_bits-1;
    --

    constant voltage_transform_ratio   : real := (max_voltage/2.0**word_length);
    constant real_to_int_voltage_ratio : real := (2.0**word_length/max_voltage);

    constant integrator_radix : integer := 15;
    constant integrator_gain      : real := 2.0**integrator_radix;
    constant stoptime             : real := 10.0e-3;
    constant simulation_time_step : real := stoptime/3000.0;

    signal simulation_time : real := 0.0;
    signal number_of_calculation_cycles : integer := 0;

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
        return integer(1.0/capacitance_value*simulation_time_step*integrator_gain);
    end capacitance_is;
    ----
    function inductance_is
    (
        inductor_value : real
    )
    return integer
    is
    begin
        return capacitance_is(inductor_value);
    end inductance_is;
    ----
    function resistance_is
    (
        resistance : real
    )
    return integer
    is
    begin
        return integer(resistance * integrator_gain);
    end resistance_is;

    function resistance_is
    (
        resistance : integer
    )
    return integer
    is
    begin
        return resistance_is(real(resistance));
    end resistance_is;
    ----

    signal lcr_model  : lcr_model_record  := init_lcr_filter(inductance_is(470.0e-6), capacitance_is(20.0e-6), resistance_is(1));
    signal multiplier : multiplier_record := init_multiplier;
    signal output_voltage   : real := 0.0;
    signal input_voltage    : real := 325.0;
    signal inductor_current : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simulation_time > stoptime;
        check(abs(output_voltage - input_voltage) < 50.0, "error in input and output voltages too high");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        file file_handler : text open write_mode is "inverter_simulation_results.dat";
        Variable row      : line;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier);
            create_test_lcr_filter(
                hw_multiplier     => multiplier,
                lcr_filter_object => lcr_model,
                load_current      => 0,
                u_in              => int_voltage(input_voltage));

            if lcr_filter_calculation_is_ready(lcr_model) or simulation_counter = 0 then
                request_lcr_filter_calculation(lcr_model);

                simulation_time <= simulation_time + simulation_time_step;
                write(row , simulation_time + simulation_time_step   , left , 30);
                write(row , real_voltage(get_inductor_current(lcr_model))  , left , 30);
                write(row , real_voltage(get_capacitor_voltage(lcr_model)) , left , 30);

                writeline(file_handler , row);
                number_of_calculation_cycles <= number_of_calculation_cycles + 1;
            end if;

            output_voltage   <= real_voltage(get_capacitor_voltage(lcr_model));
            inductor_current <= real_voltage(get_inductor_current(lcr_model));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
