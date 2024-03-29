library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;
    use work.adc_interface_pkg.all;
    use work.power_electronics_control_pkg.all;

package power_electronics_pkg is

    type power_electronics_FPGA_input_group is record
        adc_interface_FPGA_in  : adc_interface_FPGA_input_group;
        pll_locked : std_logic;
    end record;
    
    type power_electronics_FPGA_output_group is record
        leds                 : std_logic_vector(3 downto 0);
        aux_pwm_out          : std_logic;

        adc_interface_FPGA_out : adc_interface_FPGA_output_group;
        power_electronics_control_FPGA_out : power_electronics_control_FPGA_output_group; 
    end record;
    
    type power_electronics_data_input_group is record
        bus_in : fpga_interconnect_record;
    end record;
    
    type power_electronics_data_output_group is record
        bus_out : fpga_interconnect_record;
    end record;
    
end package power_electronics_pkg;
------------------------------------------------------------------------
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;
    use work.rtl_counter_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;
    use work.aux_pwm_pkg.all;
    use work.adc_interface_pkg.all;

library math_library_26x26;
    use math_library_26x26.multiplier_pkg.all;
    use math_library_26x26.lcr_filter_model_pkg.all;

entity power_electronics is
    port (
        system_clocks              : in system_clocks_record;
        power_electronics_FPGA_in  : in power_electronics_FPGA_input_group;
        power_electronics_FPGA_out : out power_electronics_FPGA_output_group;
        power_electronics_data_in  : in power_electronics_data_input_group;
        power_electronics_data_out : out power_electronics_data_output_group
    );
end entity power_electronics;


architecture rtl of power_electronics is

    alias clock_120Mhz is system_clocks.clock_120Mhz;
    alias leds is power_electronics_FPGA_out.leds;
    alias bus_from_master is power_electronics_data_in.bus_in;
    alias bus_out is power_electronics_data_out.bus_out;

    signal counter : integer range 0 to 2**16-1 := 0; 
    signal model_calculation_counter : integer range 0 to 2**16-1 := 1199; 
    signal slow_counter : integer range 0 to 2**16-1 := 0; 
    signal led_state : std_logic_vector(3 downto 0) := (others => '0');

    signal data_from_power_electronics : integer range 0 to 2**16-1 := 220;
------------------------------------------------------------------------
    signal system_is_started : boolean := false;
    signal multiplier22x22 : multiplier_record := init_multiplier;
    signal lcr_model : lcr_model_record := init_lcr_model_integrator_gains(300, 2e3);

    signal stimulus_counter : integer range 0 to 2**15-1 := 20e3;
    signal uin : integer range 0 to 2**16-1 := 1500;

    signal aux_pwm : aux_pwm_record := init_aux_period_and_duty(period => 500, duty_cycle => 220);

    signal sdm_clock_counter : integer range 0 to 2**4-1 := 0;
    signal sdm_io_clock : std_logic := '0';

    signal dab_io_data        : std_logic := '0';
    signal output_sdm_io_data : std_logic := '0';
    signal grid_sdm_io_data   : std_logic := '0';

    signal startup_delay_counter : natural := 25e4;

    function to_std_logic_vector
    (
        data : integer
    )
    return std_logic_vector 
    is
    begin
        return std_logic_vector(to_unsigned(data, 3));
    end to_std_logic_vector;

    signal adc_interface_data_in  : adc_interface_data_input_group;
    signal adc_interface_data_out : adc_interface_data_output_group;
    signal bus_from_adc_interface : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_power_electronics : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_power_electronics_control : fpga_interconnect_record := init_fpga_interconnect;

begin

    power_electronics_FPGA_out.aux_pwm_out <= aux_pwm.pwm_out;

------------------------------------------------------------------------
    combine_buses : process(clock_120mhz)
    begin
        if rising_edge(clock_120mhz) then

            bus_out <= bus_from_adc_interface 
                       and bus_from_power_electronics 
                       and bus_from_power_electronics_control;

        end if;
    end process combine_buses;	

------------------------------------------------------------------------
    u_adc_interface : entity work.adc_interface
    port map( 
              clock      => clock_120mhz,
              pll_locked => power_electronics_FPGA_in.pll_locked,
              adc_interface_FPGA_in          => power_electronics_FPGA_in.adc_interface_FPGA_in,
              adc_interface_FPGA_out         => power_electronics_FPGA_out.adc_interface_FPGA_out,
              adc_interface_data_in.bus_in   => bus_from_master,
              adc_interface_data_out.bus_out => bus_from_adc_interface);

------------------------------------------------------------------------
    led_blinker : process(clock_120Mhz)

    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_from_power_electronics);
            connect_data_to_address(bus_from_master, bus_from_power_electronics, power_electronics_data_address, data_from_power_electronics);

            connect_read_only_data_to_address(bus_from_master , bus_from_power_electronics , capacitor_voltage_address , get_capacitor_voltage(lcr_model)/64 + 32768);
            connect_read_only_data_to_address(bus_from_master , bus_from_power_electronics , capacitor_current_address , get_inductor_current(lcr_model)/16 + 32768);


            create_aux_pwm(aux_pwm);
            if data_from_power_electronics = 999 then
                start_aux_pwm(aux_pwm);
            else
                stop_aux_pwm(aux_pwm);
            end if;

            if write_to_address_is_requested(bus_from_master, power_electronics_data_address) and get_data(bus_from_master) = 1 then
                system_is_started <= true;
            end if;

            if write_to_address_is_requested(bus_from_master, power_electronics_data_address) and get_data(bus_from_master) = 0 then
                system_is_started <= false;
            end if;

            if system_is_started then
                leds <= led_state;
            else
                leds <= (others => '0');
            end if;

            count_down_from(counter, 10e3);
            if counter = 0 then
                count_down_from(slow_counter, 4e3);

                blink_leds(slow_counter, led_state(0),(4.0e3/1.0));
                blink_leds(slow_counter, led_state(1),(4.0e3/2.0));
                blink_leds(slow_counter, led_state(2),(4.0e3/3.0));
                blink_leds(slow_counter, led_state(3),(4.0e3/4.0));

            end if;

            ---
            create_multiplier(multiplier22x22);
            create_test_lcr_filter(multiplier22x22, lcr_model, get_capacitor_voltage(lcr_model)/128, uin*8);
            count_down_from(model_calculation_counter, 1199);
            if model_calculation_counter = 0 then
                request_lcr_filter_calculation(lcr_model);

                if stimulus_counter > 0 then
                    stimulus_counter <= stimulus_counter - 1;
                else
                    stimulus_counter <= 20e3;
                    uin <= -uin;
                end if;
            end if;

        end if; --rising_edge
    end process led_blinker;	

------------------------------------------------------------------------
    u_power_electronics_control : entity work.power_electronics_control
    port map (
        system_clocks   => system_clocks,
        power_electronics_control_FPGA_out         => power_electronics_FPGA_out.power_electronics_control_FPGA_out,
        power_electronics_control_data_in.bus_in   => bus_from_master,
        power_electronics_control_data_out.bus_out => bus_from_power_electronics_control);

------------------------------------------------------------------------
end rtl;
