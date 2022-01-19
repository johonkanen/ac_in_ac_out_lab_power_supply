library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package system_control_pkg is

    type system_clock_record is record
        clock_120Mhz : std_logic;
    end record;
    
    type system_control_FPGA_input_group is record
        buttons : std_logic_vector(1 downto 0);
    end record;
    
    type system_control_FPGA_output_group is record
        leds : std_logic_vector(3 downto 0);
    end record;
    
    component system_control is
        port (
            system_control_clocks   : in system_clock_record;
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
