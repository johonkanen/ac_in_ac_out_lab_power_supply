library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_control_pkg.all;

entity efinix_top is
    port (
        clock_120Mhz : in std_logic;
        leds         : out std_logic_vector(3 downto 0)
    );
end entity efinix_top;


architecture rtl of efinix_top is

    signal system_control_clocks   : system_clock_record;
    signal system_control_FPGA_in  : system_control_FPGA_input_group;
    signal system_control_FPGA_out : system_control_FPGA_output_group;

begin

    system_control_clocks <= (clock_120Mhz => clock_120Mhz);

    u_system_control : system_control
    port map( system_control_clocks ,
    	  system_control_FPGA_in    ,
    	  system_control_FPGA_out);

end rtl;
