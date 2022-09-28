LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.uart_communication_pkg.all;

entity uart_communication_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of uart_communication_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
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

    signal testy_thing : std_logic_vector(7*memory_array'high downto 0);

    signal bus_from_main : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_process1 : fpga_interconnect_record := init_fpga_interconnect;

    signal data_in_1 : integer := 44252;
    signal number_of_transmitted_words : integer := 7;

    signal uart_communication : uart_communcation_record := init_uart_communcation;
    signal receive_is_ready : boolean := false;

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

    transmit_buffer <= uart_communication.transmit_buffer;
    number_of_transmitted_words <= uart_communication.number_of_transmitted_words;

    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_uart(uart_tx_data_in);
            init_bus(bus_from_main);
            create_uart_communication(uart_communication, uart_rx_data_out, uart_tx_data_in, uart_tx_data_out);

            if simulation_counter = 0 then 
                transmit_words_with_uart(uart_communication, (x"04", x"cd", x"ef", x"55", x"25"));
            end if;
            if simulation_counter = 2000 then 
                transmit_words_with_uart(uart_communication, (x"ac", x"dc"));
            end if;

            receive_is_ready <= frame_has_been_received(uart_communication);

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
        end if; --rising_edge
    end process process1;	
------------------------------------------------------------------------
end vunit_simulation;
