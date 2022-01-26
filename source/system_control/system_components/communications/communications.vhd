library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.communications_pkg.all;
    use work.uart_pkg.all;
    use work.rtl_counter_pkg.all;

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

    alias clock is communications_clocks.clock; 

    signal uart_clocks   : uart_clock_group;
    signal uart_FPGA_out : uart_FPGA_output_group;
    signal uart_data_in  : uart_data_input_group;
    signal uart_data_out : uart_data_output_group;

    signal counter : integer range 0 to 2**12-1 := 1199; 

    signal data_from_uart : integer range 0 to 2**16-1 :=0;

begin

    communications_FPGA_out <= (uart_FPGA_out => uart_FPGA_out);

    test_uart : process(clock)
        
    begin
        if rising_edge(clock) then
            init_uart(uart_data_in);

            receive_data_from_uart(uart_data_out, data_from_uart);

            count_down_from(counter, 1199);
            if counter = 0 then
                transmit_16_bit_word_with_uart(uart_data_in, data_from_uart);
            end if;

        end if; --rising_edge
    end process test_uart;	

    uart_clocks <=(clock => clock);
    u_uart : uart
    port map( uart_clocks,
          communications_FPGA_in.uart_FPGA_in,
    	  uart_FPGA_out,
    	  uart_data_in,
    	  uart_data_out);

end rtl;
