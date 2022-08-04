library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.power_electronics_pkg.all;
    use work.uart_pkg.all;
    use work.communications_pkg.all;
    use work.fpga_interconnect_pkg.all;

package component_interconnect_pkg is

    type component_interconnect_FPGA_input_group is record
        -- power_electronics_FPGA_in  : power_electronics_FPGA_input_group;
        communications_FPGA_in  : communications_FPGA_input_group;
    end record;
    
    type component_interconnect_FPGA_output_group is record
        power_electronics_FPGA_out : power_electronics_FPGA_output_group;
        communications_FPGA_out    : communications_FPGA_output_group;
    end record;
    
    type component_interconnect_data_input_group is record
        power_electronics_data_in  : power_electronics_data_input_group;
        bus_in : fpga_interconnect_record;

    end record;
    
    type component_interconnect_data_output_group is record
        power_electronics_data_out : power_electronics_data_output_group;
        bus_out : fpga_interconnect_record;
    end record;

end package component_interconnect_pkg;
------------------------------------------------------------------------
------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.system_clocks_pkg.all;
    use work.component_interconnect_pkg.all;
    use work.communications_pkg.all;
    use work.power_electronics_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.test_module_pkg.all;

entity component_interconnect is
    port (
        system_clocks                   : in system_clocks_record;
        component_interconnect_FPGA_in  : in component_interconnect_FPGA_input_group;
        component_interconnect_FPGA_out : out component_interconnect_FPGA_output_group;
        component_interconnect_data_in  : in component_interconnect_data_input_group;
        component_interconnect_data_out : out component_interconnect_data_output_group
    );
end entity component_interconnect;

architecture rtl of component_interconnect is

    signal power_electronics_data_in  : power_electronics_data_input_group;
    signal power_electronics_data_out : power_electronics_data_output_group;

    signal communications_clocks   : communications_clock_group;
    signal communications_data_in  : communications_data_input_group;
    signal communications_data_out : communications_data_output_group;

    signal test_module_data_in  : test_module_data_input_group;
    signal test_module_data_out : test_module_data_output_group;

    alias bus_out is communications_data_out.bus_out;
    signal bus_in : fpga_interconnect_record := init_fpga_interconnect;

begin 

------------------------------------------------------------------------
    component_interconnect_data_out <= (power_electronics_data_out => power_electronics_data_out,
                                        bus_out                    => bus_out);

------------------------------------------------------------------------
    combine_buses : process(system_clocks.clock_120Mhz)
    begin
        if rising_edge(system_clocks.clock_120Mhz) then

            bus_in <= component_interconnect_data_in.bus_in and
                      power_electronics_data_out.bus_out    and
                      test_module_data_out.bus_out;

        end if;
    end process combine_buses;	

------------------------------------------------------------------------
    power_electronics_data_in <= (bus_in => bus_out);

    u_power_electronics : entity work.power_electronics
    port map( system_clocks              ,
              -- component_interconnect_FPGA_in.power_electronics_FPGA_in  ,
              component_interconnect_FPGA_out.power_electronics_FPGA_out ,
              power_electronics_data_in  ,
              power_electronics_data_out);

------------------------------------------------------------------------
    communications_clocks  <= (clock => system_clocks.clock_120Mhz);
    communications_data_in <= (bus_in => bus_in);

    u_communications : entity work.communications
    port map( communications_clocks                               ,
          component_interconnect_FPGA_in.communications_FPGA_in   ,
          component_interconnect_FPGA_out.communications_FPGA_out ,
    	  communications_data_in                                  ,
    	  communications_data_out);

------------------------------------------------------------------------
    test_module_data_in <= (bus_in => bus_out);

    u_test_module : entity work.test_module
    port map( system_clocks        ,
              test_module_data_in  ,
              test_module_data_out);
------------------------------------------------------------------------
end rtl;
