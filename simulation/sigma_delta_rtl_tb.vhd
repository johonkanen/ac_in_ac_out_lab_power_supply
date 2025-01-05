LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.sigma_delta_simulation_model_pkg.all;
    use work.sigma_delta_cic_filter_pkg.all;

entity delta_sigma_rtl_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of delta_sigma_rtl_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal sdm_model : sdm_model_record := init_sdm_model;
    signal sdm_io : std_logic := '0';
    signal sini : real := 0.0;

    type filter_array is array (integer range 0 to 12) of real;
    type unsig_filter_array is array (integer range 0 to 5) of integer;

    signal integrator : integer_array := (0,0,0);
    signal derivator : integer_array := (0,0,0);
    signal counter : natural := 0;
    signal output : natural := 0;

    procedure calculate_first_order_filters
    (
        signal filter_object_array : inout filter_array;
        input : in std_logic;
        gain : in real
    ) is
        variable x : filter_array;
    begin
        x(0) := filter_object_array(0) -(filter_object_array(0) - input)/gain;
        filter_object_array(0) <= x(0);
        for i in 1 to x'high loop
            x(i) := filter_object_array(i) +(x(i-1) - filter_object_array(i))/gain;
            filter_object_array(i) <= x(i);
        end loop;
    end calculate_first_order_filters;

    procedure calculate_first_order_filters
    (
        signal filter_object_array : inout unsig_filter_array;
        input : in std_logic
    ) is
        variable x : unsig_filter_array;
        variable input_unsig : integer;
    begin
        if input = '1' then 
            input_unsig := 2**24;
        else
            input_unsig := -2**24;
        end if;
        x(0) := filter_object_array(0) + (input_unsig - filter_object_array(0)) / 2;
        filter_object_array(0) <= x(0);
        for i in 1 to x'high loop
            x(i) := filter_object_array(i) +(x(i-1) - filter_object_array(i)) / 2;
            filter_object_array(i) <= x(i);
        end loop;
    end calculate_first_order_filters;
------------------------------------------------------------------------
------------------------------------------------------------------------
    signal filters : filter_array := (others => 0.0);
    signal unsig_filters : unsig_filter_array := (others => 0);
------------------------------------------------------------------------

    constant filter_gain : real := 2.0;
    signal maximum_error : real := 0.0;
    signal demodulation_error : real := 0.0;
    signal filter_out : real := 0.0;
    signal rtl_filter_out : real := 0.0;

    signal cic_filter_output : real := 0.0;
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
        function sign (a : real) return real 
        is
            variable retval : real;
        begin
            if a < 0.0 then
                retval := -1.0;
            else
                retval := 1.0;
            end if;
            return retval;
        end sign;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_sdm_model(sdm_model, sini);
            request_sdm_model_calculation(sdm_model);
            sdm_io <= get_1bit_sdm_output(sdm_model);

            sini <= real(simulation_counter mod 1000)/2000.0;

            if sdm_model_is_ready(sdm_model) then
                calculate_first_order_filters(filters, sdm_io, filter_gain);
                calculate_first_order_filters(unsig_filters, sdm_io);
                calculate_cic_filter(integrator, derivator, counter, output, get_sdm_output(sdm_model));
            end if;

            demodulation_error <= (sini - filters(filters'high));
            filter_out <= filters(filters'high);
            rtl_filter_out <= real(unsig_filters(unsig_filters'high))/2.0**(24);
            cic_filter_output <= real(output)/2.0**15;

            -- allow initial model start to have larger error
            -- if simulation_counter > 500 then
            --     check( abs(demodulation_error) < 0.1, "maximum filter error should be less than 0.1");
            --     if maximum_error < abs(demodulation_error) then
            --         maximum_error <= abs(demodulation_error);
            --     end if;
            -- end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
