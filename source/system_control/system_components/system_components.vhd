library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library work;
    use work.system_clocks_pkg.all;
    use work.system_components_pkg.all;
    use work.power_electronics_pkg.all;

entity system_components is
    port (
        system_clocks : in system_clocks_record;
        system_components_FPGA_in : in system_components_FPGA_input_group;
        system_components_FPGA_out : out system_components_FPGA_output_group; 
        system_components_data_in : in system_components_data_input_group;
        system_components_data_out : out system_components_data_output_group
    );
end entity system_components;

architecture rtl of system_components is

    signal power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
    signal power_electronics_FPGA_out : power_electronics_FPGA_output_group;
    signal power_electronics_data_in  : power_electronics_data_input_group;
    signal power_electronics_data_out : power_electronics_data_output_group;

begin 

    system_components_FPGA_out <= (power_electronics_FPGA_out => power_electronics_FPGA_out);

------------------------------------------------------------------------
    -- comm module to be added here
------------------------------------------------------------------------
    u_power_electronics : power_electronics
    port map( system_clocks,
              system_components_FPGA_in.power_electronics_FPGA_in,
              power_electronics_FPGA_out ,
              power_electronics_data_in  ,
              power_electronics_data_out);

------------------------------------------------------------------------
end rtl;
