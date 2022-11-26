library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.communications_pkg.all;
    use work.power_electronics_pkg.all;

package system_control_pkg is

    type system_control_FPGA_input_group is record
        power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
        communications_FPGA_in  : communications_FPGA_input_group;
    end record;
    
    type system_control_FPGA_output_group is record
        power_electronics_FPGA_out : power_electronics_FPGA_output_group;
        communications_FPGA_out    : communications_FPGA_output_group;
    end record;
    
end package system_control_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.system_register_addresses_pkg.all;
    use work.power_electronics_pkg.all;
    use work.communications_pkg.all;

    use work.main_state_machine_pkg.all;

entity system_control is
    port (
        system_clocks   : in system_clocks_record;
        system_control_FPGA_in  : in system_control_FPGA_input_group;
        system_control_FPGA_out : out system_control_FPGA_output_group
    );
end entity system_control;

architecture rtl of system_control is

    alias clock_120Mhz is system_clocks.clock_120Mhz;

    signal power_electronics_data_in  : power_electronics_data_input_group;
    signal power_electronics_data_out : power_electronics_data_output_group;

    signal communications_clocks   : communications_clock_group;
    signal communications_data_in  : communications_data_input_group;
    signal communications_data_out : communications_data_output_group;

    signal register_in_system_control : integer range 0 to 2**16-1 := 44252;
    signal main_state_machine : main_state_machine_record := init_main_state_machine;
------------------------------------------------------------------------
    signal command_from_bus : integer range 0 to 2**16-1 := 0;
------------------------------------------------------------------------
    signal bus_from_system_control : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_master : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_to_master : fpga_interconnect_record   := init_fpga_interconnect;
------------------------------------------------------------------------
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    main_system_controller : process(clock_120Mhz)
        variable action_is : list_of_actions;
        
    begin
        if rising_edge(clock_120Mhz) then

            init_bus(bus_from_system_control);

            connect_read_only_data_to_address(bus_from_master , bus_from_system_control , system_control_data_address   , register_in_system_control);
            connect_data_to_address(bus_from_master           , bus_from_system_control , system_control_data_address+1 , command_from_bus);
            connect_read_only_data_to_address(bus_from_master , bus_from_system_control , 0                             , 44252);


            create_main_state_machine( 
                main_state_machine                                  ,
                (start_has_been_commanded   => command_from_bus = 1 ,
                dc_link_is_ready            => false                ,
                system_is_running           => false                ,
                system_is_stopped           => false                ,
                fault_has_been_acknowledged => false                ,
                trip_has_been_detected      => false)               ,
                action_is
            );

        end if; --rising_edge
    end process main_system_controller;	

------------------------------------------------------------------------
    combine_buses : process(clock_120Mhz) begin
        if rising_edge(clock_120Mhz) then
             bus_to_master <= power_electronics_data_out.bus_out and bus_from_system_control;
        end if;
    end process combine_buses;	
------------------------------------------------------------------------
    power_electronics_data_in <= (bus_in => bus_from_master);

    u_power_electronics : entity work.power_electronics
    port map( system_clocks ,
              system_control_FPGA_in.power_electronics_FPGA_in ,
              system_control_FPGA_out.power_electronics_FPGA_out       ,
              power_electronics_data_in                                ,
              power_electronics_data_out);

------------------------------------------------------------------------

    u_communications : entity work.communications
    port map( communications_clocks.clock => system_clocks.clock_120Mhz                      ,
          communications_FPGA_in          => system_control_FPGA_in.communications_FPGA_in   ,
          communications_FPGA_out         => system_control_FPGA_out.communications_FPGA_out ,
          communications_data_in.bus_in   => bus_to_master                                   ,
    	  communications_data_out.bus_out => bus_from_master);

------------------------------------------------------------------------
end rtl;
