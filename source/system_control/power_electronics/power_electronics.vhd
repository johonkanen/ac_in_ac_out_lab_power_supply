library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.spi_sar_adc_pkg.all;
    use work.fpga_interconnect_pkg.all;

package power_electronics_pkg is

    type power_electronics_FPGA_input_group is record
        dab_sdm_data        : std_logic;
        grid_sdm_data       : std_logic;
        output_sdm_data     : std_logic;
        spi_sar_adc_FPGA_in : spi_sar_adc_FPGA_input_group;
        spi_sar_adc_FPGA_in2 : spi_sar_adc_FPGA_input_group;
    end record;
    
    type power_electronics_FPGA_output_group is record
        leds                 : std_logic_vector(3 downto 0);
        aux_pwm_out          : std_logic;
        dab_sdm_clock        : std_logic;
        grid_inu_sdm_clock   : std_logic;
        output_inu_sdm_clock : std_logic;

        spi_sar_adc_FPGA_out : spi_sar_adc_FPGA_output_group;
        spi_sar_adc_FPGA_out2 : spi_sar_adc_FPGA_output_group;
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
    use work.ads7056_pkg.all;

library math_library_26x26;
    use math_library_26x26.multiplier_pkg.all;
    use math_library_26x26.lcr_filter_model_pkg.all;

    use work.sigma_delta_cic_filter_pkg.all;
    use work.spi_sar_adc_pkg.all;

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
    alias bus_in is power_electronics_data_in.bus_in;
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

    signal dab_cic_filter        : cic_filter_record := init_cic_filter;
    signal grid_inu_cic_filter   : cic_filter_record := init_cic_filter;
    signal output_inu_cic_filter : cic_filter_record := init_cic_filter;

    signal startup_delay_counter : natural := 25e4;
    signal reset_n : std_logic := '0';

    signal spi_sar_adc_data_in  : spi_sar_adc_data_input_group;
    signal spi_sar_adc_data_out : spi_sar_adc_data_output_group;

    signal spi_sar_adc_data_in2  : spi_sar_adc_data_input_group;
    signal spi_sar_adc_data_out2 : spi_sar_adc_data_output_group;

    signal ads7056 : ads7056_record := init_ads7056(7);
    signal ads7056_pri : ads7056_record := init_ads7056(7);

begin

    power_electronics_FPGA_out.aux_pwm_out <= aux_pwm.pwm_out;
    power_electronics_FPGA_out.spi_sar_adc_FPGA_out.chip_select <= ads7056.chip_select_out;
    power_electronics_FPGA_out.spi_sar_adc_FPGA_out.spi_clock  <= ads7056.clock_divider.divided_clock;

    power_electronics_FPGA_out.spi_sar_adc_FPGA_out2.chip_select <= ads7056_pri.chip_select_out;
    power_electronics_FPGA_out.spi_sar_adc_FPGA_out2.spi_clock  <= ads7056_pri.clock_divider.divided_clock;
------------------------------------------------------------------------
    led_blinker : process(clock_120Mhz)

    begin
        if rising_edge(clock_120Mhz) then
            create_ads7056(ads7056, power_electronics_FPGA_in.spi_sar_adc_FPGA_in.spi_serial_data);
            create_ads7056(ads7056_pri, power_electronics_FPGA_in.spi_sar_adc_FPGA_in2.spi_serial_data);

            init_bus(bus_out);
            connect_data_to_address(bus_in, bus_out, power_electronics_data_address, data_from_power_electronics);

            connect_read_only_data_to_address(bus_in , bus_out , capacitor_voltage_address , get_capacitor_voltage(lcr_model)/64 + 32768);
            connect_read_only_data_to_address(bus_in , bus_out , capacitor_voltage_address+1  , get_inductor_current(lcr_model)/16 + 32768);

            connect_read_only_data_to_address(bus_in , bus_out , 5000 , get_cic_filter_output(dab_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5001 , get_cic_filter_output(output_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5002 , get_cic_filter_output(grid_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5003 , get_ad_measurement(ads7056));
            connect_read_only_data_to_address(bus_in , bus_out , 5004 , get_ad_measurement(ads7056_pri));

            create_aux_pwm(aux_pwm);
            if data_from_power_electronics = 999 then
                start_aux_pwm(aux_pwm);
            end if;

            if data_from_power_electronics = 0 then
                stop_aux_pwm(aux_pwm);
            end if;

            if write_to_address_is_requested(bus_in, power_electronics_data_address) and get_data(bus_in) = 1 then
                system_is_started <= true;
            end if;

            if write_to_address_is_requested(bus_in, power_electronics_data_address) and get_data(bus_in) = 0 then
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
                if ads7056_has_been_initialized(ads7056) then
                    request_ad_conversion(ads7056);
                    request_ad_conversion(ads7056_pri);
                end if;
                start_ad_conversion(spi_sar_adc_data_in2);

                if stimulus_counter > 0 then
                    stimulus_counter <= stimulus_counter - 1;
                else
                    stimulus_counter <= 20e3;
                    uin <= -uin;
                end if;
            end if;

            reset_n <= '0';
            if startup_delay_counter > 0 then
                startup_delay_counter <= startup_delay_counter - 1;
            else
                reset_n <= '1';
            end if;
            if startup_delay_counter = 1 then
                initialize_ads7056(ads7056);
                initialize_ads7056(ads7056_pri);
            end if;

        end if; --rising_edge
    end process led_blinker;	

------------------------------------------------------------------------
    test_sdm_clocks : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then
            if sdm_clock_counter > 0 then
                sdm_clock_counter <= sdm_clock_counter - 1;
            else
                sdm_clock_counter <= 5;
            end if;

            if sdm_clock_counter > 2 then
                sdm_io_clock <= '1';
            else
                sdm_io_clock <= '0';
            end if;

            if sdm_clock_counter = 3 then
                dab_io_data        <= power_electronics_FPGA_in.dab_sdm_data   ;
                grid_sdm_io_data   <= power_electronics_FPGA_in.grid_sdm_data  ;
                output_sdm_io_data <= power_electronics_FPGA_in.output_sdm_data  ;

                calculate_cic_filter(dab_cic_filter        , dab_io_data);
                calculate_cic_filter(grid_inu_cic_filter   , grid_sdm_io_data);
                calculate_cic_filter(output_inu_cic_filter , output_sdm_io_data);
            end if;

            power_electronics_FPGA_out.grid_inu_sdm_clock   <= sdm_io_clock;
            power_electronics_FPGA_out.output_inu_sdm_clock <= sdm_io_clock;
            power_electronics_FPGA_out.dab_sdm_clock        <= sdm_io_clock;

        end if; --rising_edge
    end process test_sdm_clocks;	
------------------------------------------------------------------------
end rtl;
