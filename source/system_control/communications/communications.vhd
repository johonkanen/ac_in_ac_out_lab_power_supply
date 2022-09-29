library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

package communications_pkg is

    type communications_clock_group is record
        clock : std_logic;
    end record;
    
    type communications_FPGA_input_group is record
        uart_rx : std_logic;
    end record;
    
    type communications_FPGA_output_group is record
        uart_tx : std_logic;
    end record;
    
    type communications_data_input_group is record
        bus_in : fpga_interconnect_record;
    end record;
    
    type communications_data_output_group is record
        bus_out : fpga_interconnect_record;
    end record;

end package communications_pkg;
    
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.communications_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.uart_communication_pkg.all;
    use work.uart_rx_pkg.all;
    use work.uart_tx_pkg.all;

entity communications is
    port (
        communications_clocks   : in communications_clock_group;
        communications_FPGA_in  : in communications_FPGA_input_group;
        communications_FPGA_out : out communications_FPGA_output_group;
        communications_data_in  : in communications_data_input_group;
        communications_data_out : out communications_data_output_group
    );
end entity communications;

architecture rtl of communications is

    alias clock   is communications_clocks.clock;
    alias bus_out is communications_data_out.bus_out;
    alias bus_in  is communications_data_in.bus_in;

    signal uart_rx_data_in  : uart_rx_data_input_group;
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_data_in    : uart_tx_data_input_group;
    signal uart_tx_data_out   : uart_tx_data_output_group;
    signal uart_communication : uart_communcation_record := init_uart_communcation;

    signal counter : integer range 0 to 2**12-1 := 1199; 

begin

------------------------------------------------------------------------
------------------------------------------------------------------------
    test_uart : process(clock)
    begin
        if rising_edge(clock) then

            init_uart(uart_tx_data_in);
            init_bus(bus_out);
            create_uart_communication(uart_communication, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            ------------------------------------------------------------------------
            if frame_has_been_received(uart_communication) then
                CASE get_command(uart_communication) is
                    WHEN read_is_requested_from_address_from_uart =>
                        request_data_from_address(bus_out, get_command_address(uart_communication));

                    WHEN write_to_address_is_requested_from_uart =>
                        write_data_to_address(bus_out, get_command_address(uart_communication), get_command_data(uart_communication));

                    WHEN stream_data_from_address =>
                        -- do something to stream data

                    WHEN others => -- do nothing
                end CASE;
            end if;
            
            if write_to_address_is_requested(bus_in, 0) then
                transmit_words_with_uart(uart_communication, write_data_to_register(0, get_data(bus_in)));
            end if;
            
        end if; -- rising_edge
    end process test_uart;	
------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map((clock => clock)                        ,
         (uart_rx => communications_FPGA_in.uart_rx) ,
    	  uart_rx_data_in                            ,
    	  uart_rx_data_out); 
------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
    port map((clock => clock)                                         ,
          uart_tx_fpga_out.uart_tx => communications_FPGA_out.uart_tx ,
    	  uart_tx_data_in => uart_tx_data_in                          ,
    	  uart_tx_data_out => uart_tx_data_out);
------------------------------------------------------------------------
end rtl;
