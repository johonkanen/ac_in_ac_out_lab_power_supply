library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;
    use work.uart_pkg.all;
    use work.communications_pkg.all;

package component_interconnect_pkg is

    type component_interconnect_FPGA_input_group is record
        power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
        communications_FPGA_in  : communications_FPGA_input_group;
    end record;
    
    type component_interconnect_FPGA_output_group is record
        power_electronics_FPGA_out : power_electronics_FPGA_output_group;
        communications_FPGA_out    : communications_FPGA_output_group;
    end record;
    
    type component_interconnect_data_input_group is record
        power_electronics_data_in  : power_electronics_data_input_group;
    end record;
    
    type component_interconnect_data_output_group is record
        power_electronics_data_out : power_electronics_data_output_group;
    end record;
    
    component component_interconnect is
        port (
            system_clocks                   : in system_clocks_record;
            component_interconnect_FPGA_in  : in component_interconnect_FPGA_input_group;
            component_interconnect_FPGA_out : out component_interconnect_FPGA_output_group;
            component_interconnect_data_in  : in component_interconnect_data_input_group;
            component_interconnect_data_out : out component_interconnect_data_output_group
        );
    end component component_interconnect;
    
    -- signal component_interconnect_FPGA_in  : component_interconnect_FPGA_input_group;
    -- signal component_interconnect_FPGA_out : component_interconnect_FPGA_output_group;
    -- signal component_interconnect_data_in  : component_interconnect_data_input_group;
    -- signal component_interconnect_data_out : component_interconnect_data_output_group
    
    -- u_component_interconnect_pkg : component_interconnect_pkg
    -- port map( component_interconnect_clocks,
    -- 	  component_interconnect_FPGA_in,
    --	  component_interconnect_FPGA_out,
    --	  component_interconnect_data_in,
    --	  component_interconnect_data_out);
    

end package component_interconnect_pkg;

