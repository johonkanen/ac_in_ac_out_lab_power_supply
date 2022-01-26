library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.component_interconnect_pkg.all;

entity system_control is
    port (
        system_control_clocks   : in system_clocks_record;
        system_control_FPGA_in  : in system_control_FPGA_input_group;
        system_control_FPGA_out : out system_control_FPGA_output_group
    );
end entity system_control;

architecture rtl of system_control is

    alias clock_120Mhz is system_control_clocks.clock_120Mhz;
    signal component_interconnect_data_in  : component_interconnect_data_input_group;
    signal component_interconnect_data_out : component_interconnect_data_output_group;


------------------------------------------------------------------------
begin
------------------------------------------------------------------------

    main_system_controller : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then


        end if; --rising_edge
    end process main_system_controller;	

------------------------------------------------------------------------
    u_component_interconnect_pkg : component_interconnect
    port map( system_control_clocks                               ,
    	  system_control_FPGA_in.component_interconnect_FPGA_in   ,
    	  system_control_FPGA_out.component_interconnect_FPGA_out ,
    	  component_interconnect_data_in                          ,
    	  component_interconnect_data_out);
------------------------------------------------------------------------
end rtl;
