library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.system_clocks_pkg.all;
    use work.fpga_interconnect_pkg.all;

package test_module_pkg is

    type test_module_FPGA_input_group is record
        clock : std_logic;
    end record;
    
    type test_module_FPGA_output_group is record
        leds : std_logic_vector(3 downto 0);
    end record;
    
    type test_module_data_input_group is record
        bus_in : fpga_interconnect_record;
    end record;
    
    type test_module_data_output_group is record
        bus_out : fpga_interconnect_record;
    end record;
    
    -- signal test_module_FPGA_in  : test_module_FPGA_input_group;
    -- signal test_module_FPGA_out : test_module_FPGA_output_group;
    -- signal test_module_data_in  : test_module_data_input_group;
    -- signal test_module_data_out : test_module_data_output_group
    
    -- u_test_module : test_module
    -- port map( test_module_clocks,
    -- 	  test_module_FPGA_in,
    --	  test_module_FPGA_out,
    --	  test_module_data_in,
    --	  test_module_data_out);
    
end package test_module_pkg;
