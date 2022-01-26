library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.uart_pkg.all;

package communications_pkg is

    type communications_clock_group is record
        clock : std_logic;
    end record;
    
    type communications_FPGA_input_group is record
        uart_FPGA_in  : uart_FPGA_input_group;
    end record;
    
    type communications_FPGA_output_group is record
        uart_FPGA_out : uart_FPGA_output_group;
    end record;
    
    type communications_data_input_group is record
        clock : std_logic;
    end record;
    
    type communications_data_output_group is record
        clock : std_logic;
    end record;
    
    component communications is
        port (
            communications_clocks : in communications_clock_group; 
            communications_FPGA_in : in communications_FPGA_input_group;
            communications_FPGA_out : out communications_FPGA_output_group; 
            communications_data_in : in communications_data_input_group;
            communications_data_out : out communications_data_output_group
        );
    end component communications;
    
    -- signal communications_clocks   : communications_clock_group;
    -- signal communications_FPGA_in  : communications_FPGA_input_group;
    -- signal communications_FPGA_out : communications_FPGA_output_group;
    -- signal communications_data_in  : communications_data_input_group;
    -- signal communications_data_out : communications_data_output_group
    
    -- u_communications : communications
    -- port map( communications_clocks,
    -- 	  communications_FPGA_in,
    --	  communications_FPGA_out,
    --	  communications_data_in,
    --	  communications_data_out);

end package communications_pkg;
