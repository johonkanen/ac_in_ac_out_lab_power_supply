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
    use work.communications_pkg.all;

entity communications_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of communications_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal uart_rx_data_in  : uart_rx_data_input_group := (number_of_clocks_per_bit => 24);
    signal uart_rx_data_out : uart_rx_data_output_group;

    signal uart_tx_data_in  : uart_tx_data_input_group := (false, (others => '0'), 24);
    signal uart_tx_data_out : uart_tx_data_output_group;

    signal memory : memory_array := (others => (others => '0'));
    signal memory_address : integer range memory_array'range := 0;

    signal transmit_buffer : memory_array := (others => x"00");

    signal bus_from_main : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_process1 : fpga_interconnect_record := init_fpga_interconnect;

    signal data_in_1 : integer := 57;
    signal data_read_with_uart : integer := 0;
    signal number_of_transmitted_words : integer := 7;

    signal uart_protocol : uart_communcation_record := init_uart_communcation;
------------------------------------------------------------------------
    signal communications_FPGA_in  : communications_FPGA_input_group;
    signal communications_FPGA_out : communications_FPGA_output_group;
    signal communications_data_in  : communications_data_input_group;
    signal communications_data_out : communications_data_output_group;
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(data_in_1 = 25, "failed to write data to register");
        check(data_read_with_uart = 25, "failed to read data from register");
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

            init_uart(uart_tx_data_in, 24);
            set_number_of_clocks_per_bit(uart_rx_data_in, 24);
            create_uart_protocol(uart_protocol, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            if simulation_counter = 0 then 
                transmit_words_with_uart(uart_protocol, write_data_to_register(1, 25));
            end if;
            
            if simulation_counter = 2000 then 
                transmit_words_with_uart(uart_protocol, read_data_from_register(1));
            end if;

            if frame_has_been_received(uart_protocol) then
                data_read_with_uart <= get_command_data(uart_protocol);
            end if;

        end if; -- rising_edge
    end process stimulus;	

------------------------------------------------------------------------

    u_communications : entity work.communications
    port map( (clock                      => simulator_clock)                             ,
          communications_FPGA_in          => communications_FPGA_in  ,
          communications_FPGA_out         => communications_FPGA_out ,
          communications_data_in.bus_in   => bus_from_process1       ,
    	  communications_data_out.bus_out => bus_from_main);

------------------------------------------------------------------------
    u_uart_rx : entity work.uart_rx
    port map((clock => simulator_clock)                              ,
          uart_rx_FPGA_in.uart_rx => communications_FPGA_out.uart_tx ,
    	  uart_rx_data_in => uart_rx_data_in                         ,
    	  uart_rx_data_out => uart_rx_data_out); 

------------------------------------------------------------------------
    u_uart_tx : entity work.uart_tx
    port map((clock                => simulator_clock)               ,
    	  uart_tx_FPGA_out.uart_tx => communications_FPGA_in.uart_rx ,
    	  uart_tx_data_in          => uart_tx_data_in                ,
    	  uart_tx_data_out         => uart_tx_data_out);
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
