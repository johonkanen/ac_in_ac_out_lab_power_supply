------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

package power_electronics_control_pkg is

    -- type power_electronics_control_FPGA_input_group is record
    --     output_inverter_control_FPGA_in  : output_inverter_control_FPGA_input_record;
    -- end record;

    type power_electronics_control_FPGA_output_group is record
        grid_gate_low : std_logic;
    end record;
    
    type power_electronics_control_data_input_group is record
        bus_in : fpga_interconnect_record;
    end record;
    
    type power_electronics_control_data_output_group is record
        bus_out : fpga_interconnect_record;
    end record;

end package power_electronics_control_pkg;
------------------------------------------------------------------------
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.power_electronics_control_pkg.all;
    use work.system_clocks_pkg.all;
    use work.fpga_interconnect_pkg.all;

    library float;
    use float.float_alu_pkg.all;

entity power_electronics_control is
    port (
        system_clocks   : in system_clocks_record;
        power_electronics_control_FPGA_out : out power_electronics_control_FPGA_output_group; 
        power_electronics_control_data_in : in power_electronics_control_data_input_group;
        power_electronics_control_data_out : out power_electronics_control_data_output_group
    );
end entity power_electronics_control;

architecture rtl of power_electronics_control is

    alias clock_120Mhz is system_clocks.clock_120Mhz;
    alias bus_in is power_electronics_control_data_in.bus_in;
    alias bus_out is power_electronics_control_data_out.bus_out;
    signal register_in_power_electronics : integer range 0 to 2**16-1 := 22e3;

begin

    test_power_electronics : process(clock_120mhz)
        
    begin
        if rising_edge(clock_120mhz) then
            init_bus(bus_out);
            connect_data_to_address(bus_in, bus_out, 22e3, register_in_power_electronics);

        end if; --rising_edge
    end process test_power_electronics;	

end rtl;
