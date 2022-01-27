library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.power_electronics_control_pkg.all;
    use work.output_inverter_control_pkg.all;

entity power_electronics_control is
    port (
        power_electronics_control_clocks : in power_electronics_control_clock_group; 
        power_electronics_control_FPGA_in : in power_electronics_control_FPGA_input_group;
        power_electronics_control_FPGA_out : out power_electronics_control_FPGA_output_group; 
        power_electronics_control_data_in : in power_electronics_control_data_input_group;
        power_electronics_control_data_out : out power_electronics_control_data_output_group
    );
end entity power_electronics_control;

architecture rtl of power_electronics_control is

signal output_inverter_control_clocks   : output_inverter_control_clock_record;
signal output_inverter_control_FPGA_in  : output_inverter_control_FPGA_input_record;
signal output_inverter_control_FPGA_out : output_inverter_control_FPGA_output_record;
signal output_inverter_control_data_in  : output_inverter_control_data_input_record;
signal output_inverter_control_data_out : output_inverter_control_data_output_record;
    

begin

u_output_inverter_control : output_inverter_control
port map( output_inverter_control_clocks,
	  power_electronics_control_FPGA_in.output_inverter_control_FPGA_in,
	  power_electronics_control_FPGA_out.output_inverter_control_FPGA_out,
	  output_inverter_control_data_in,
	  output_inverter_control_data_out);

end rtl;

