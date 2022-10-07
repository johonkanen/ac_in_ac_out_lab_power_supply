LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.uart_protocol_pkg.all;

entity uart_protocol_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of uart_protocol_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 15000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal uart_rx_FPGA_in  : uart_rx_FPGA_input_group;
    signal uart_rx_data_in  : uart_rx_data_input_group;
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_FPGA_out  : uart_tx_FPGA_output_group;
    signal uart_tx_data_in  : uart_tx_data_input_group;
    signal uart_tx_data_out : uart_tx_data_output_group;

    constant time_between_packages : integer := 10;
    signal transmit_timer : integer range 0 to 127 := 1;

    signal memory : memory_array := (others => (others => '0'));
    signal memory_address : integer range memory_array'range := 0;

    signal transmit_buffer : memory_array := (others => x"00");

    signal bus_from_main : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_process1 : fpga_interconnect_record := init_fpga_interconnect;

    signal data_in_1 : integer := 57;
    signal number_of_transmitted_words : integer := 7;

    signal uart_protocol : uart_communcation_record := init_uart_communcation;
    signal receive_is_ready : boolean := false;
    signal number_of_registers_to_stream : integer range 0 to 2**23-1 := 0;
    signal stream_address : integer range 0 to 2**16-1 := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    transmit_buffer             <= uart_protocol.transmit_buffer;
    number_of_transmitted_words <= uart_protocol.number_of_transmitted_words;

    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_uart(uart_tx_data_in);
            init_bus(bus_from_main);
            create_uart_protocol(uart_protocol, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            ------------------------------------------------------------------------
            if frame_has_been_received(uart_protocol) then

                CASE get_command(uart_protocol) is
                    WHEN read_is_requested_from_address_from_uart =>
                        request_data_from_address(bus_from_main, get_command_address(uart_protocol));

                    WHEN write_to_address_is_requested_from_uart =>
                        write_data_to_address(bus_from_main, get_command_address(uart_protocol), get_command_data(uart_protocol));

                    WHEN stream_data_from_address =>
                        number_of_registers_to_stream <= get_number_of_registers_to_stream(uart_protocol);
                        stream_address                <= get_command_address(uart_protocol);
                        request_data_from_address(bus_from_main, get_command_address(uart_protocol));
                        send_stream_data_packet(uart_protocol, 0);

                    WHEN others => -- do nothing
                end CASE;
            end if;
            -----------------------


            if write_to_address_is_requested(bus_from_process1, 0) then
                if (number_of_registers_to_stream = 0)  then
                    transmit_words_with_uart(uart_protocol, write_data_to_register(1, get_data(bus_from_process1)));
                else
                    send_stream_data_packet(uart_protocol, get_data(bus_from_process1));
                end if;
            end if;

            if simulation_counter > 3541 then
                if number_of_registers_to_stream > 0 then
                    if transmit_is_ready(uart_protocol) then
                        number_of_registers_to_stream <= number_of_registers_to_stream - 1;
                        request_data_from_address(bus_from_main, stream_address);
                        send_stream_data_packet(uart_protocol, number_of_registers_to_stream);
                    end if;
                end if;
            end if;

            ------------------------------------------------------------------------
            -- test injection
            CASE simulation_counter is
                WHEN 0 =>
                    -- transmit_words_with_uart(uart_protocol, read_data_from_register(1));
                    transmit_words_with_uart(uart_protocol, write_data_to_register(1, 25));
                WHEN 2e3 => 
                    transmit_words_with_uart(uart_protocol, read_data_from_register(2) & int24_to_bytes(5));
                    -- transmit_words_with_uart(uart_protocol, write_data_to_register(1, 55));
                WHEN others =>
            end CASE;

            receive_is_ready <= frame_has_been_received(uart_protocol);
            ------------------------------------------------------------------------


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map((clock => simulator_clock)        ,
         (uart_rx => uart_tx_FPGA_out.uart_tx) ,
    	  uart_rx_data_in                      ,
    	  uart_rx_data_out); 

------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
    port map((clock => simulator_clock) ,
    	  uart_tx_FPGA_out              ,
    	  uart_tx_data_in               ,
    	  uart_tx_data_out);

------------------------------------------------------------------------
    process1 : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            init_bus(bus_from_process1);
            connect_data_to_address(bus_from_main, bus_from_process1, 1, data_in_1);
        end if; --rising_edge
    end process process1;	
------------------------------------------------------------------------
end vunit_simulation;
