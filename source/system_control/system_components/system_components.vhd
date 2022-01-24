library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;
    use work.system_clocks_pkg.all;
    use work.component_interconnect_pkg.all;
    use work.power_electronics_pkg.all;

entity component_interconnect is
    port (
        system_clocks : in system_clocks_record;
        component_interconnect_FPGA_in : in component_interconnect_FPGA_input_group;
        component_interconnect_FPGA_out : out component_interconnect_FPGA_output_group; 
        component_interconnect_data_in : in component_interconnect_data_input_group;
        component_interconnect_data_out : out component_interconnect_data_output_group
    );
end entity component_interconnect;

architecture rtl of component_interconnect is

    signal power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
    signal power_electronics_FPGA_out : power_electronics_FPGA_output_group;
    signal power_electronics_data_in  : power_electronics_data_input_group;
    signal power_electronics_data_out : power_electronics_data_output_group;

begin 

    component_interconnect_FPGA_out <= (power_electronics_FPGA_out => power_electronics_FPGA_out);
    component_interconnect_data_out <= (power_electronics_data_out => power_electronics_data_out);

------------------------------------------------------------------------
    -- comm module to be added here
------------------------------------------------------------------------
    power_electronics_data_in <= component_interconnect_data_in.power_electronics_data_in;

    u_power_electronics : power_electronics
    port map( system_clocks,
              component_interconnect_FPGA_in.power_electronics_FPGA_in,
              power_electronics_FPGA_out ,
              power_electronics_data_in  ,
              power_electronics_data_out);

------------------------------------------------------------------------
end rtl;
