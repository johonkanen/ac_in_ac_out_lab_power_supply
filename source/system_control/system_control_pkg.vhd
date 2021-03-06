library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.component_interconnect_pkg.all;

package system_control_pkg is

    type system_control_FPGA_input_group is record
        component_interconnect_FPGA_in : component_interconnect_FPGA_input_group;
    end record;
    
    type system_control_FPGA_output_group is record
        component_interconnect_FPGA_out : component_interconnect_FPGA_output_group; 
    end record;
    
    component system_control is
        port (
            system_control_clocks   : in system_clocks_record;
            system_control_FPGA_in  : in system_control_FPGA_input_group;
            system_control_FPGA_out : out system_control_FPGA_output_group
        );
    end component system_control;
    
    -- signal system_control_clocks   : system_control_clock_group;
    -- signal system_control_FPGA_in  : system_control_FPGA_input_group;
    -- signal system_control_FPGA_out : system_control_FPGA_output_group;
    
    -- u_system_control : system_control
    -- port map( system_control_clocks ,
    -- 	  system_control_FPGA_in       ,
    --	  system_control_FPGA_out);

end package system_control_pkg;
