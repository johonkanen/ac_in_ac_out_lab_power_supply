library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


package output_inverter_control_pkg is

type output_inverter_control_clock_record is record
    core_clock : std_logic;
end record;

type output_inverter_control_FPGA_input_record is record
    button1 : std_logic;
end record;

type output_inverter_control_FPGA_output_record is record
    leds : std_logic_vector(3 downto 0);
end record;

type output_inverter_control_data_input_record is record
    clock : std_logic;
end record;

type output_inverter_control_data_output_record is record
    clock : std_logic;
end record;

component output_inverter_control is
    port (
        output_inverter_control_clocks   : in output_inverter_control_clock_record;
        output_inverter_control_FPGA_in  : in output_inverter_control_FPGA_input_record;
        output_inverter_control_FPGA_out : out output_inverter_control_FPGA_output_record;
        output_inverter_control_data_in  : in output_inverter_control_data_input_record;
        output_inverter_control_data_out : out output_inverter_control_data_output_record
    );
end component output_inverter_control;

-- signal output_inverter_control_clocks   : output_inverter_control_clock_record;
-- signal output_inverter_control_FPGA_in  : output_inverter_control_FPGA_input_record;
-- signal output_inverter_control_FPGA_out : output_inverter_control_FPGA_output_record;
-- signal output_inverter_control_data_in  : output_inverter_control_data_input_record;
-- signal output_inverter_control_data_out : output_inverter_control_data_output_record

-- u_output_inverter_control : output_inverter_control
-- port map( output_inverter_control_clocks,
-- 	  output_inverter_control_FPGA_in,
--	  output_inverter_control_FPGA_out,
--	  output_inverter_control_data_in,
--	  output_inverter_control_data_out);


end package output_inverter_control_pkg;
