library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;

package uart_communication_pkg is

    type base_array is array (natural range <>) of std_logic_vector(7 downto 0);
    subtype memory_array is base_array(0 to 7);

    type uart_communcation_record is record
        number_of_transmitted_words : integer range 0 to 7;
        transmit_buffer             : memory_array;
        is_ready                    : boolean;
        is_requested                : boolean;

        ------------------------------
        receive_buffer           : memory_array;
        receive_address: integer range 0 to 7;
        number_of_received_words : integer range 0 to 7;
        receive_is_ready         : boolean;
        receive_timeout          : integer range 0 to 1023;
    end record;

    constant init_uart_communcation : uart_communcation_record := (0, (others => x"00"), false, false, (others => x"00"), 0,0, false, 0);

------------------------------------------------------------------------
    procedure create_uart_communication (
        signal uart_communcation_object : inout uart_communcation_record;
        uart_rx        : in uart_rx_data_output_group;
        signal uart_tx_in : out uart_tx_data_input_group;
        uart_tx_out       : in uart_tx_data_output_group);
------------------------------------------------------------------------
    procedure transmit_words_with_uart (
        signal uart_communcation_object : out uart_communcation_record;
        data_words_in : base_array );

    function frame_has_been_received ( uart_communcation_object : uart_communcation_record)
        return boolean;

end package uart_communication_pkg;

package body uart_communication_pkg is

------------------------------------------------------------------------
    procedure create_uart_communication
    (
        signal uart_communcation_object : inout uart_communcation_record;
        uart_rx           : in uart_rx_data_output_group;
        signal uart_tx_in : out uart_tx_data_input_group;
        uart_tx_out       : in uart_tx_data_output_group
    ) is
        alias m is uart_communcation_object;
    begin
        init_uart(uart_tx_in);
        
        m.is_ready <= false;
        m.is_requested <= false;

        if m.number_of_transmitted_words > 0 then
            if uart_tx_is_ready(uart_tx_out) or m.is_requested then
                transmit_8bit_data_package(uart_tx_in, m.transmit_buffer(0));
                m.transmit_buffer <= m.transmit_buffer(1 to 7) & x"ff";
                m.number_of_transmitted_words <= m.number_of_transmitted_words - 1;
            end if;
        else
            if uart_tx_is_ready(uart_tx_out) then
                m.is_ready <= true;
            end if;
        end if;

        --------------------------------------------------
        m.receive_is_ready <= false;

        if m.receive_timeout > 0 then
            m.receive_timeout <= m.receive_timeout - 1;
        end if;

        if m.receive_timeout = 1 then
            m.number_of_received_words <= 0;
            m.receive_address <= 0;
        end if;

        if uart_rx_data_is_ready(uart_rx) then
            m.receive_timeout <= 1000;
            m.receive_buffer(m.receive_address) <= get_uart_rx_data(uart_rx);
            m.receive_address <= m.receive_address + 1;

            if m.number_of_received_words > 0 then
                m.number_of_received_words <= m.number_of_received_words - 1;
            else
                m.number_of_received_words <= get_uart_rx_data(uart_rx);
            end if;

            if m.number_of_received_words = 1 then
                m.receive_is_ready <= true;
                m.receive_timeout <= 0;
                m.receive_address <= 0;
            end if;
        end if;
        
    end create_uart_communication;

------------------------------------------------------------------------
    procedure transmit_words_with_uart
    (
        signal uart_communcation_object : out uart_communcation_record;
        data_words_in : base_array 
    ) is
        alias m is uart_communcation_object;
    begin
        m.number_of_transmitted_words <= data_words_in'length+1;

        m.transmit_buffer(0) <= std_logic_vector(to_unsigned(data_words_in'length, 8));
        for i in 1 to data_words_in'high+1 loop
            m.transmit_buffer(i) <= data_words_in(i-1);
        end loop;
        m.is_requested <= true;
        
    end transmit_words_with_uart;
------------------------------------------------------------------------
    function frame_has_been_received
    (
        uart_communcation_object : uart_communcation_record
    )
    return boolean
    is
    begin
        return uart_communcation_object.receive_is_ready;
    end frame_has_been_received;
------------------------------------------------------------------------

end package body uart_communication_pkg;
