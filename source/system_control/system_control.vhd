library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.system_clocks_pkg.all;
    use work.system_control_pkg.all;
    use work.system_components_pkg.all;
    use work.rtl_counter_pkg.all;

entity system_control is
    port (
        system_control_clocks   : in system_clocks_record;
        system_control_FPGA_in  : in system_control_FPGA_input_group;
        system_control_FPGA_out : out system_control_FPGA_output_group
    );
end entity system_control;

architecture rtl of system_control is

    alias clock_120Mhz is system_control_clocks.clock_120Mhz;
    alias leds is system_control_FPGA_out.leds;
    signal system_components_data_in  : system_components_data_input_group;
    signal system_components_data_out : system_components_data_output_group;

    type system_states is (wait_for_run_command, init, normal_operation, power_down, fault, acknowledge_fault);

    signal counter : integer range 0 to 2**16-1 := 0; 
    signal slow_counter : integer range 0 to 2**16-1 := 0; 
    signal led_state : std_logic_vector(3 downto 3) := (others => '0');
------------------------------------------------------------------------

begin
------------------------------------------------------------------------

    main_system_controller : process(clock_120Mhz)
        
    begin
        if rising_edge(clock_120Mhz) then

            leds <= led_state;
            count_down_from(counter, 10e3);
            if counter = 0 then
                count_down_from(slow_counter, 5e3);
                blink_leds(slow_counter, led_state(3),(5.0e3/4.0*3.0));
            end if;


        end if; --rising_edge
    end process main_system_controller;	

------------------------------------------------------------------------
    u_system_components_pkg : system_components
    port map( system_control_clocks                          ,
    	  system_control_FPGA_in.system_components_FPGA_in   ,
    	  system_control_FPGA_out.system_components_FPGA_out ,
    	  system_components_data_in                          ,
    	  system_components_data_out);
------------------------------------------------------------------------
end rtl;
