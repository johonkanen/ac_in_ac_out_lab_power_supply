library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;

package system_components_pkg is

    type system_components_FPGA_input_group is record
        power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
    end record;
    
    type system_components_FPGA_output_group is record
        power_electronics_FPGA_out : power_electronics_FPGA_output_group;
    end record;
    
    type system_components_data_input_group is record
        power_electronics_data_in  : power_electronics_data_input_group;
    end record;
    
    type system_components_data_output_group is record
        power_electronics_data_out : power_electronics_data_output_group;
    end record;
    
    component system_components is
        port (
            system_clocks              : in system_clocks_record;
            system_components_FPGA_in  : in system_components_FPGA_input_group;
            system_components_FPGA_out : out system_components_FPGA_output_group;
            system_components_data_in  : in system_components_data_input_group;
            system_components_data_out : out system_components_data_output_group
        );
    end component system_components;
    
    -- signal system_components_FPGA_in  : system_components_FPGA_input_group;
    -- signal system_components_FPGA_out : system_components_FPGA_output_group;
    -- signal system_components_data_in  : system_components_data_input_group;
    -- signal system_components_data_out : system_components_data_output_group
    
    -- u_system_components_pkg : system_components_pkg
    -- port map( system_components_clocks,
    -- 	  system_components_FPGA_in,
    --	  system_components_FPGA_out,
    --	  system_components_data_in,
    --	  system_components_data_out);
    

end package system_components_pkg;

