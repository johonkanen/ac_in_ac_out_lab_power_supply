library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.component_interconnect_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;

    use work.main_state_machine_pkg.all;

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
    signal main_state_machine : main_state_machine_record := init_main_state_machine;
------------------------------------------------------------------------
    signal command_from_bus : integer range 0 to 2**16-1 := 0;
------------------------------------------------------------------------
begin


    component_interconnect_FPGA_in <= system_control_FPGA_in.component_interconnect_FPGA_in;
    system_control_FPGA_out        <= (component_interconnect_FPGA_out => component_interconnect_FPGA_out);

------------------------------------------------------------------------
    main_system_controller : process(clock_120Mhz)
        variable action_is : list_of_actions;
        
    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_out);
            connect_read_only_data_to_address(bus_in , bus_out , system_control_data_address , register_in_system_control);
            connect_data_to_address(bus_in , bus_out , system_control_data_address+1 , command_from_bus);

            create_main_state_machine( main_state_machine,
                (start_has_been_commanded   => command_from_bus = 1,
                dc_link_is_ready            => false,
                system_is_running           => false,
                system_is_stopped           => false,
                fault_has_been_acknowledged => false,
                trip_has_been_detected      => false),
                action_is
            );

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
