LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.sigma_delta_simulation_model_pkg.all;

entity delta_sigma_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of delta_sigma_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal sdm_model : sdm_model_record := init_sdm_model;
    signal sdm_io : std_logic := '0';
    signal sini : real := 0.0;

    type filter_array is array (integer range 0 to 3) of real;
    signal filters : filter_array := (0.0,0.0,0.0,0.0);
------------------------------------------------------------------------
    procedure calculate_first_order_filters
    (
        signal filter_object_array : inout filter_array;
        input : in std_logic;
        gain : in real
    ) is
        variable x : filter_array;
    begin
        x(0) := filter_object_array(0) -(filter_object_array(0) - input)*gain;
        x(1) := filter_object_array(1) +(x(0) - filter_object_array(1))*gain;
        x(2) := filter_object_array(2) +(x(1) - filter_object_array(2))*gain;
        x(3) := filter_object_array(3) +(x(2) - filter_object_array(3))*gain;

        filter_object_array(0) <= x(0);
        filter_object_array(1) <= x(1);
        filter_object_array(2) <= x(2);
        filter_object_array(3) <= x(3);
        
    end calculate_first_order_filters;
------------------------------------------------------------------------

    constant filter_gain : real := 0.125;
    signal maximum_error : real := 0.0;
    signal demodulation_error : real := 0.0;
    signal filter_out : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_sdm_model(sdm_model, sini);
            request_sdm_model_calculation(sdm_model);
            sdm_io <= get_1bit_sdm_output(sdm_model);

            sini <= 0.1 * sin((real(simulation_counter)/3000.0*math_pi) mod (2.0*math_pi));

            if sdm_model_is_ready(sdm_model) then
                calculate_first_order_filters(filters, sdm_io, filter_gain);
            end if;

            demodulation_error <= (sini - filters(3));
            filter_out <= filters(3);

            -- allow initial model start to have larger error
            if simulation_counter > 500 then
                check( abs(demodulation_error) < 0.1, "maximum filter error should be less than 0.1");
                if maximum_error < abs(demodulation_error) then
                    maximum_error <= abs(demodulation_error);
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
