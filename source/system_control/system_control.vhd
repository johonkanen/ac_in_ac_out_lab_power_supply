library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.component_interconnect_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;
    use work.multiplier_pkg.all;
    use work.rtl_counter_pkg.all;

library math_library_18x18;
    use math_library_18x18.multiplier_pkg.all;
    use math_library_18x18.first_order_filter_pkg.all;

library math_library_22x22;
    use math_library_22x22.multiplier_pkg.all;
    use math_library_22x22.first_order_filter_pkg.all;

library math_library_26x26;
    use math_library_26x26.multiplier_pkg.all;
    use math_library_26x26.first_order_filter_pkg.all;

entity system_control is
    port (
        system_control_clocks   : in system_clocks_record;
        system_control_FPGA_in  : in system_control_FPGA_input_group;
        system_control_FPGA_out : out system_control_FPGA_output_group
    );
end entity system_control;

architecture rtl of system_control is


    alias clock_120Mhz is system_control_clocks.clock_120Mhz;
    signal component_interconnect_FPGA_in  : component_interconnect_FPGA_input_group;
    signal component_interconnect_FPGA_out : component_interconnect_FPGA_output_group;
    signal component_interconnect_data_in  : component_interconnect_data_input_group;
    signal component_interconnect_data_out : component_interconnect_data_output_group;

    alias bus_out is component_interconnect_data_in.bus_in;
    alias bus_in is component_interconnect_data_out.bus_out;

    signal register_in_system_control : integer range 0 to 2**16-1 := 44252;
    signal testi : math_library_18x18.multiplier_pkg.int18 := 0;
    signal counter : integer range 0 to 2**16-1 := 0; 

    signal multiplier_18x18  : math_library_18x18.multiplier_pkg.multiplier_record := math_library_18x18.multiplier_pkg.init_multiplier;
    signal multiplier_22x22  : math_library_22x22.multiplier_pkg.multiplier_record := math_library_22x22.multiplier_pkg.init_multiplier;
    signal multiplier_26x26  : math_library_26x26.multiplier_pkg.multiplier_record := math_library_26x26.multiplier_pkg.init_multiplier;

    signal filter18 : math_library_18x18.first_order_filter_pkg.first_order_filter_record := math_library_18x18.first_order_filter_pkg.init_first_order_filter;
    signal filter22 : math_library_22x22.first_order_filter_pkg.first_order_filter_record := math_library_22x22.first_order_filter_pkg.init_first_order_filter;
    signal filter26 : math_library_26x26.first_order_filter_pkg.first_order_filter_record := math_library_26x26.first_order_filter_pkg.init_first_order_filter;

    signal filter_input : math_library_18x18.multiplier_pkg.int18 := 0;

------------------------------------------------------------------------
begin


    component_interconnect_FPGA_in <= system_control_FPGA_in.component_interconnect_FPGA_in;
    system_control_FPGA_out        <= (component_interconnect_FPGA_out => component_interconnect_FPGA_out);

------------------------------------------------------------------------
    main_system_controller : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_out);
            create_multiplier(multiplier_18x18);
            create_multiplier(multiplier_22x22);
            create_multiplier(multiplier_26x26);

            create_first_order_filter(filter18, multiplier_18x18, 0.0002);
            create_first_order_filter(filter22, multiplier_22x22, 0.0002);
            create_first_order_filter(filter26, multiplier_26x26, 0.0002);

            connect_read_only_data_to_address(bus_in , bus_out , system_control_data_address , register_in_system_control);
            connect_read_only_data_to_address(bus_in , bus_out , 5588                        , filter_input);
            connect_read_only_data_to_address(bus_in , bus_out , 5589                        , get_filter_output(filter18)/2);
            connect_read_only_data_to_address(bus_in , bus_out , 5590                        , get_filter_output(filter22)/32);
            connect_read_only_data_to_address(bus_in , bus_out , 5591                        , get_filter_output(filter26)/512);

            count_down_from(counter, 1199);
            if counter = 0 then
                testi <= testi + 1;
                filter_input <= (testi mod 16384);
                filter_data(filter18, filter_input*256/32);
                filter_data(filter22, filter_input*4096/32);
                filter_data(filter26, filter_input*65536/32);
            end if;

        end if; --rising_edge
    end process main_system_controller;	

------------------------------------------------------------------------
    u_component_interconnect : component_interconnect
    port map( system_control_clocks       ,
          component_interconnect_FPGA_in  ,
          component_interconnect_FPGA_out ,
    	  component_interconnect_data_in  ,
    	  component_interconnect_data_out);

------------------------------------------------------------------------
end rtl;
