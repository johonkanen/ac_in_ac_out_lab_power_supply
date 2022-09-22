library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package adc_interface_pkg is

    type adc_interface_FPGA_input_group is record
        clock : std_logic;
    end record;
    
    type adc_interface_FPGA_output_group is record
        clock : std_logic;
    end record;
    
    type adc_interface_data_input_group is record
        clock : std_logic;
    end record;
    
    type adc_interface_data_output_group is record
        clock : std_logic;
    end record;
    
end package adc_interface_pkg;

package body adc_interface_pkg is

end package body adc_interface_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.adc_interface_pkg.all;

entity adc_interface is
    port (
        clock : in std_logic;
        adc_interface_FPGA_in  : in adc_interface_FPGA_input_group;
        adc_interface_FPGA_out : out adc_interface_FPGA_output_group;
        adc_interface_data_in  : in adc_interface_data_input_group;
        adc_interface_data_out : out adc_interface_data_output_group
    );
end entity adc_interface;

architecture rtl of adc_interface is

begin

end rtl;
