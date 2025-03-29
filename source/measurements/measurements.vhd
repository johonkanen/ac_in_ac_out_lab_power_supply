
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity measurements is
    port (
        main_clock : in std_logic

        ; ads_7056_chip_select_pri : out std_logic
        ; ads_7056_clock_pri       : out std_logic
        ; ads_7056_input_data_pri  : in std_logic

        ; ads_7056_chip_select : out std_logic
        ; ads_7056_clock       : out std_logic
        ; ads_7056_input_data  : in std_logic

         ; test_data3              : out std_logic_vector(15 downto 0)
         ; conversion_requested    : in boolean
         ; bus_from_communications : in fpga_interconnect_record
         ; bus_from_measurements   : out fpga_interconnect_record

    );
end entity measurements;

architecture rtl of measurements is

    use work.ads7056_pkg.all;
    use work.real_to_fixed_pkg.all;
    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;

    package mpy_pkg is new work.multiplier_generic_pkg generic map(24,1,1);
        use mpy_pkg.all;

    package div_pkg is new work.division_generic_pkg generic map(mpy_pkg, g_max_shift => 8);
        use div_pkg.all;


    ---- measurement module signals
    constant pri_input_voltage_gain   : real := 1.0/16.763636363636365;
    constant pri_input_voltage_offset : real := 8137.90909090909 * pri_input_voltage_gain;

    constant pri_dc_link_gain   : real := 1.0/16.857479572273963;
    constant pri_dc_link_offset : real := -15.196959245805374 * pri_dc_link_gain;

    constant pri_bridge_voltage_gain   : real := -1.0/16.327272727272728;
    constant pri_bridge_voltage_offset : real := 8153.272727272727 * pri_bridge_voltage_gain;

    constant c_measurement_radix : positive := 11;

    signal meas_mult : multiplier_record := init_multiplier;

    signal pri_input_voltage   : mpy_signed := (others => '0');
    signal pri_dc_link_voltage : mpy_signed := (others => '0');
    signal pri_bridge_voltage  : mpy_signed := (others => '0');
    signal conversion_is_ready : boolean := false;

    signal sample_and_hold_delay_counter : natural range 0 to 255;
    signal mux_counter : natural range 0 to 3 := 0;
    signal pri_mux_pos : natural range 0 to 7 := 0;
    signal conversion_mux_pos : natural range 0 to 7 := 0;

    signal pri_offset : mpy_signed := (others => '0');
    signal pri_gain   : mpy_signed := (others => '0');

    signal conversion_counter : natural range 0 to 7 := 0;

    ---- end measurement module signals


begin

    measurement_scaling : process(main_clock)
    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_measurements);

            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 2  , get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 3  , get_converted_measurement(sec_ads7056));
            connect_data_to_address(bus_from_communications           , bus_from_measurements , 5  , test_data3);
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 9  , std_logic_vector(pri_input_voltage(15+2 downto 0+2)));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 10 , std_logic_vector(pri_dc_link_voltage(15+2 downto 0+2)));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 11 , std_logic_vector(pri_bridge_voltage(15+2 downto 0+2)));

            create_multiplier(meas_mult);

            create_ads7056_driver(pri_ads7056         
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);

            if conversion_requested then
                request_conversion(pri_ads7056);
                request_conversion(sec_ads7056);
            end if;

            if ad_conversion_is_ready(pri_ads7056) then
                conversion_counter <= 0;
                -- sample_and_hold_delay_counter <= 0;
            end if;

            conversion_mux_pos <= to_integer(unsigned(test_data3(2 downto 0)));
            conversion_is_ready <= false;
            CASE conversion_counter is
                WHEN 0 =>
                    conversion_counter <= conversion_counter + 1;
                    CASE conversion_mux_pos is
                        WHEN 0 => 
                            pri_offset <= to_fixed(pri_input_voltage_offset , mpy_signed'length , c_measurement_radix);
                            pri_gain   <= to_fixed(pri_input_voltage_gain   , mpy_signed'length , mpy_signed'length-1);
                        WHEN 1 => 
                            pri_offset <= to_fixed(pri_dc_link_offset , mpy_signed'length , c_measurement_radix);
                            pri_gain   <= to_fixed(pri_dc_link_gain   , mpy_signed'length , mpy_signed'length-1);
                        WHEN 3 => 
                            pri_offset <= to_fixed(pri_bridge_voltage_offset , mpy_signed'length , c_measurement_radix);
                            pri_gain   <= to_fixed(pri_bridge_voltage_gain   , mpy_signed'length , mpy_signed'length-1);

                        WHEN others => -- do nothing?
                    end CASE;
                WHEN 1 =>
                    conversion_counter <= conversion_counter + 1;
                    multiply(meas_mult, resize(signed(get_converted_measurement(pri_ads7056)), mpy_signed'length), pri_gain);
                WHEN 2 =>
                    if multiplier_is_ready(meas_mult) then
                        conversion_counter  <= conversion_counter + 1;
                        conversion_is_ready <= true;
                        CASE conversion_mux_pos is 
                            WHEN 0 => pri_input_voltage   <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, c_measurement_radix) - pri_offset;
                            WHEN 1 => pri_dc_link_voltage <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, c_measurement_radix) - pri_offset;
                            WHEN 3 => pri_bridge_voltage  <= get_multiplier_result(meas_mult, mpy_signed'length-1, 0, c_measurement_radix) - pri_offset;
                            WHEN others => --do nothing
                        end CASE;
                    end if;
                WHEN others => --do nothing
            end CASE;

        end if;
    end process;

end rtl;
