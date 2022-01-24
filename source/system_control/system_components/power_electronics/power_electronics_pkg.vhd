library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;

package power_electronics_pkg is

    type power_electronics_FPGA_input_group is record
        clock : std_logic;
    end record;
    
    type power_electronics_FPGA_output_group is record
        leds : std_logic_vector(2 downto 0);
    end record;
    
    type power_electronics_data_input_group is record
        clock : std_logic;
    end record;
    
    type power_electronics_data_output_group is record
        clock : std_logic;
    end record;
    
    component power_electronics is
        port (
            system_clocks              : in system_clocks_record;
            power_electronics_FPGA_in  : in power_electronics_FPGA_input_group;
            power_electronics_FPGA_out : out power_electronics_FPGA_output_group;
            power_electronics_data_in  : in power_electronics_data_input_group;
            power_electronics_data_out : out power_electronics_data_output_group
        );
    end component power_electronics;
    
    -- signal power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
    -- signal power_electronics_FPGA_out : power_electronics_FPGA_output_group;
    -- signal power_electronics_data_in  : power_electronics_data_input_group;
    -- signal power_electronics_data_out : power_electronics_data_output_group
    
    -- u_power_electronics : power_electronics
    -- port map( power_electronics_clocks,
    -- 	  power_electronics_FPGA_in,
    --	  power_electronics_FPGA_out,
    --	  power_electronics_data_in,
    --	  power_electronics_data_out);
    
end package power_electronics_pkg;
