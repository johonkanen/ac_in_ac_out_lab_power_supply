library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.test_module_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;
    use work.rtl_counter_pkg.all;

library float;
    use float.float_type_definitions_pkg.all;
    use float.float_to_real_conversions_pkg.all;
    use float.float_alu_pkg.all;
    use float.float_first_order_filter_pkg.all;

library math_library_18x18;
    use math_library_18x18.multiplier_pkg.all;
    use math_library_18x18.first_order_filter_pkg.all;
    use math_library_18x18.lut_sine_pkg.all;

library math_library_22x22;
    use math_library_22x22.multiplier_pkg.all;
    use math_library_22x22.first_order_filter_pkg.all;

library math_library_26x26;
    use math_library_26x26.multiplier_pkg.all;
    use math_library_26x26.first_order_filter_pkg.all;


entity test_module is
    port (
        system_clocks        : in system_clocks_record;
        test_module_data_in  : in test_module_data_input_group;
        test_module_data_out : out test_module_data_output_group
    );
end entity test_module;


architecture rtl of test_module is

    alias clock_120Mhz is system_clocks.clock_120Mhz;
    alias bus_in is test_module_data_in.bus_in;
    alias bus_out is test_module_data_out.bus_out;

    signal register_in_test_module : integer range 0 to 2**16-1 := 259;
    signal testi : math_library_18x18.multiplier_pkg.int18 := 0;
    signal counter : integer range 0 to 2**16-1 := 0; 

    signal multiplier_18x18  : math_library_18x18.multiplier_pkg.multiplier_record := math_library_18x18.multiplier_pkg.init_multiplier;
    signal multiplier_22x22  : math_library_22x22.multiplier_pkg.multiplier_record := math_library_22x22.multiplier_pkg.init_multiplier;
    signal multiplier_26x26  : math_library_26x26.multiplier_pkg.multiplier_record := math_library_26x26.multiplier_pkg.init_multiplier;

    signal filter18 : math_library_18x18.first_order_filter_pkg.first_order_filter_record := math_library_18x18.first_order_filter_pkg.init_first_order_filter;
    signal filter22 : math_library_22x22.first_order_filter_pkg.first_order_filter_record := math_library_22x22.first_order_filter_pkg.init_first_order_filter;
    signal filter26 : math_library_26x26.first_order_filter_pkg.first_order_filter_record := math_library_26x26.first_order_filter_pkg.init_first_order_filter;

    signal filter_input : math_library_18x18.multiplier_pkg.int18 := 0;

    signal float_alu : float_alu_record := init_float_alu;
    signal first_order_filter : float.float_first_order_filter_pkg.first_order_filter_record := float.float_first_order_filter_pkg.init_first_order_filter;
    signal first_order_filter2 : float.float_first_order_filter_pkg.first_order_filter_record := float.float_first_order_filter_pkg.init_first_order_filter;

    signal test_float : float_record := to_float(0.0);

------------------------------------------------------------------------
    alias  filter_counter  is first_order_filter.filter_counter;
    alias  u               is first_order_filter.u             ;
    alias  y               is first_order_filter.y             ;
    alias  filter_is_ready is first_order_filter.filter_is_ready;
------------------------------------------------------------------------

    signal sine_lut : ram_record;

begin

    test : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then
            init_bus(bus_out);
            create_multiplier(multiplier_18x18);
            create_multiplier(multiplier_22x22);
            create_multiplier(multiplier_26x26);

            create_lut_sine(sine_lut);

            create_float_alu(float_alu);
            ------------------------------------------------------------------------
            filter_is_ready <= false;
            CASE filter_counter is
                WHEN 0 => 
                    subtract_and_increment_counter(float_alu, filter_counter, u, y);
                WHEN 1 =>
                    if add_is_ready(float_alu) then
                        multiply_and_increment_counter(float_alu, filter_counter  , get_add_result(float_alu) , to_float(0.01));
                    end if;

                WHEN 2 =>
                    if multiplier_is_ready(float_alu) then
                        add_and_increment_counter(float_alu, filter_counter, get_multiplier_result(float_alu), y);
                    end if;
                WHEN 3 => 
                    if add_is_ready(float_alu) then
                        filter_is_ready <= true;
                        y <= get_add_result(float_alu);
                        filter_counter <= filter_counter + 1;
                    end if;
                WHEN others =>  -- filter is ready
            end CASE;
            ------------------------------------------------------------------------

            create_first_order_filter( filter => filter18, multiplier => multiplier_18x18, time_constant => 0.0002);
            create_first_order_filter( filter => filter22, multiplier => multiplier_22x22, time_constant => 0.0002);
            create_first_order_filter( filter => filter26, multiplier => multiplier_26x26, time_constant => 0.0002);

            connect_read_only_data_to_address(bus_in , bus_out , system_control_data_address , register_in_test_module);
            connect_read_only_data_to_address(bus_in , bus_out , 5588 , filter_input);
            connect_read_only_data_to_address(bus_in , bus_out , 5589 , get_filter_output(filter18)/2);
            connect_read_only_data_to_address(bus_in , bus_out , 5590 , get_filter_output(filter22)/32);
            connect_read_only_data_to_address(bus_in , bus_out , 5591 , get_filter_output(filter26)/512);
            connect_read_only_data_to_address(bus_in , bus_out , 5592 , get_mantissa(test_float));
            connect_read_only_data_to_address(bus_in , bus_out , 5593 , get_exponent(test_float) + 100);
            connect_read_only_data_to_address(bus_in , bus_out , 5594 , get_sine_from_lut(sine_lut)/2 + 32768);

            count_down_from(counter, 1199);
            if counter = 0 then
                testi <= testi + 1;
                filter_input <= (testi mod 16384)*8;

                request_sine_from_lut(sine_lut, testi mod 2**10);

                filter_data(filter18, filter_input);
                filter_data(filter22, filter_input*16);
                filter_data(filter26, filter_input*256);

                if filter_input < 16384*4 then
                    request_float_filter(first_order_filter, to_float(0.0));
                else
                    request_float_filter(first_order_filter, to_float(-1.5e5));
                end if;
            end if;

            if float_filter_is_ready(first_order_filter) then
                test_float <= get_filter_output(first_order_filter);
            end if;

        end if; --rising_edge
    end process test;	

end rtl;
