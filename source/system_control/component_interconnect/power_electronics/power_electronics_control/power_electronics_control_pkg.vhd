library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.output_inverter_control_pkg.all;

package power_electronics_control_pkg is

    type power_electronics_control_clock_group is record
        clock : std_logic;
    end record;
    
    type power_electronics_control_FPGA_input_group is record
        output_inverter_control_FPGA_in  : output_inverter_control_FPGA_input_record;
    end record;
    
    type power_electronics_control_FPGA_output_group is record
        output_inverter_control_FPGA_out : output_inverter_control_FPGA_output_record;
    end record;
    
    type power_electronics_control_data_input_group is record
        clock : std_logic;
    end record;
    
    type power_electronics_control_data_output_group is record
        clock : std_logic;
    end record;
    
    component power_electronics_control is
        port (
            power_electronics_control_clocks : in power_electronics_control_clock_group; 
            power_electronics_control_FPGA_in : in power_electronics_control_FPGA_input_group;
            power_electronics_control_FPGA_out : out power_electronics_control_FPGA_output_group; 
            power_electronics_control_data_in : in power_electronics_control_data_input_group;
            power_electronics_control_data_out : out power_electronics_control_data_output_group
        );
    end component power_electronics_control;
    
    -- signal power_electronics_control_clocks   : power_electronics_control_clock_group;
    -- signal power_electronics_control_FPGA_in  : power_electronics_control_FPGA_input_group;
    -- signal power_electronics_control_FPGA_out : power_electronics_control_FPGA_output_group;
    -- signal power_electronics_control_data_in  : power_electronics_control_data_input_group;
    -- signal power_electronics_control_data_out : power_electronics_control_data_output_group
    
    -- u_power_electronics_control : power_electronics_control
    -- port map( power_electronics_control_clocks,
    -- 	  power_electronics_control_FPGA_in,
    --	  power_electronics_control_FPGA_out,
    --	  power_electronics_control_data_in,
    --	  power_electronics_control_data_out);

end package power_electronics_control_pkg;
