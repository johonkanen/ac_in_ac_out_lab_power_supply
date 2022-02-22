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
    use math_library_18x18.multiplier_pkg;

library math_library_22x22;
    use math_library_22x22.multiplier_pkg;

library math_library_26x26;
    use math_library_26x26.multiplier_pkg;

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
    signal testi : int18 := 0;
    signal counter : integer range 0 to 2**16-1 := 0; 

    signal multiplier_18x18  : math_library_18x18.multiplier_pkg.multiplier_record := math_library_18x18.multiplier_pkg.init_multiplier;
    signal multiplier_22x22  : math_library_22x22.multiplier_pkg.multiplier_record := math_library_22x22.multiplier_pkg.init_multiplier;
    signal multiplier_26x26  : math_library_26x26.multiplier_pkg.multiplier_record := math_library_26x26.multiplier_pkg.init_multiplier;
    -- signal multiplier2 : multiplier_record_21x21 := multiplier_init_values_21x21;


------------------------------------------------------------------------
begin


    component_interconnect_FPGA_in <= system_control_FPGA_in.component_interconnect_FPGA_in;
    system_control_FPGA_out        <= (component_interconnect_FPGA_out => component_interconnect_FPGA_out);

------------------------------------------------------------------------
    main_system_controller : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_out);
            math_library_18x18.multiplier_pkg.create_multiplier(multiplier_18x18);
            math_library_22x22.multiplier_pkg.create_multiplier(multiplier_22x22);
            math_library_26x26.multiplier_pkg.create_multiplier(multiplier_26x26);
            connect_read_only_data_to_address(bus_in , bus_out , system_control_data_address , register_in_system_control);
            connect_read_only_data_to_address(bus_in , bus_out , 5589                        , math_library_18x18.multiplier_pkg.get_multiplier_result(multiplier_18x18 , 15));
            connect_read_only_data_to_address(bus_in , bus_out , 5590                        , math_library_22x22.multiplier_pkg.get_multiplier_result(multiplier_22x22 , 15)+32768);
            connect_read_only_data_to_address(bus_in , bus_out , 5591                        , math_library_26x26.multiplier_pkg.get_multiplier_result(multiplier_26x26 , 15)+32768);

            count_down_from(counter, 1199);
            if counter = 0 then
                testi <= testi + 1;
                math_library_18x18.multiplier_pkg.multiply(multiplier_18x18 , abs(testi) , testi);
                math_library_22x22.multiplier_pkg.multiply(multiplier_22x22 , abs(testi) , testi);
                math_library_26x26.multiplier_pkg.multiply(multiplier_26x26 , abs(testi) , testi);
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
