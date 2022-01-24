library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.system_components_pkg.all;

entity system_control is
    port (
        system_control_clocks   : in system_clocks_record;
        system_control_FPGA_in  : in system_control_FPGA_input_group;
        system_control_FPGA_out : out system_control_FPGA_output_group
    );
end entity system_control;

architecture rtl of system_control is

    alias clock_120Mhz is system_control_clocks.clock_120Mhz;
    signal system_components_data_in  : system_components_data_input_group;
    signal system_components_data_out : system_components_data_output_group;

begin

------------------------------------------------------------------------

    u_system_components_pkg : system_components
    port map( system_control_clocks  ,
    	  system_control_FPGA_in.system_components_FPGA_in  ,
    	  system_control_FPGA_out.system_components_FPGA_out ,
    	  system_components_data_in  ,
    	  system_components_data_out);
------------------------------------------------------------------------
end rtl;
