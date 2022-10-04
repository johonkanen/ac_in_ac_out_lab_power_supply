library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.uart_tx_pkg.all;
    use work.uart_rx_pkg.all;

package uart_communication_pkg is

    constant read_is_requested_from_address_from_uart : integer := 2;
    constant write_to_address_is_requested_from_uart  : integer := 4;
    constant stream_data_from_address                 : integer := 5;

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
        receive_timeout          : integer range 0 to 2**16-1;
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

------------------------------------------------------------------------
    procedure send_stream_data_packet (
        signal uart_communcation_object : out uart_communcation_record;
        data_words_in : base_array );
------------------------------------------------------------------------
    function transmit_is_ready ( uart_communication_object : uart_communcation_record)
        return boolean;
------------------------------------------------------------------------
    function write_data_to_register ( address : integer; data : integer)
        return base_array;
------------------------------------------------------------------------
    function read_data_from_register ( address : integer)
        return base_array;
------------------------------------------------------------------------
    function get_number_of_registers_to_stream (uart_communication_object : uart_communcation_record)
        return integer;
------------------------------------------------------------------------
    function get_command ( uart_communcation_object : uart_communcation_record)
        return integer;
------------------------------------------------------------------------
    function get_command_address ( uart_communcation_object : uart_communcation_record)
        return integer;
------------------------------------------------------------------------
    function get_command_data ( uart_communcation_object : uart_communcation_record)
        return integer;
------------------------------------------------------------------------
    function int24_to_bytes ( number : integer)
        return base_array;
------------------------------------------------------------------------

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
                m.transmit_buffer <= m.transmit_buffer(1 to 7) & x"00";
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
            m.receive_timeout <= 65535;
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
    procedure send_stream_data_packet
    (
        signal uart_communcation_object : out uart_communcation_record;
        data_words_in : base_array 
    ) is
        alias m is uart_communcation_object;
    begin
        m.number_of_transmitted_words <= data_words_in'length;

        -- m.transmit_buffer(0) <= std_logic_vector(to_unsigned(data_words_in'length, 8));
        for i in 0 to data_words_in'high loop
            m.transmit_buffer(i) <= data_words_in(i);
        end loop;
        m.is_requested <= true;
        
    end send_stream_data_packet;
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
------------------------------------------------------------------------
    function int_to_bytes
    (
        number : integer
    )
    return base_array 
    is
        variable uint_number : unsigned(15 downto 0);
    begin
        uint_number := to_unsigned(number,16);
        return (std_logic_vector(uint_number(15 downto 8)) , std_logic_vector(uint_number(7 downto 0)));
    end int_to_bytes;
--------------------------------------------------
    function bytes_to_int
    (
        data : base_array
    )
    return integer
    is
    begin
        return to_integer(unsigned(data(data'left)) & unsigned(data(data'left + 1)));
    end bytes_to_int;
--------------------------------------------------
    function int24_to_bytes
    (
        number : integer
    )
    return base_array 
    is
        variable uint_number : unsigned(23 downto 0);
    begin
        uint_number := to_unsigned(number,24);
        return (std_logic_vector(uint_number(23 downto 16)) ,std_logic_vector(uint_number(15 downto 8)) , std_logic_vector(uint_number(7 downto 0)));
    end int24_to_bytes;
------------------------------------------------------------------------
------------------------------------------------------------------------
    function write_data_to_register
    (
        address : integer;
        data : integer
    )
    return base_array
    is
    begin
        return int_to_bytes(address) & int_to_bytes(data);
    end write_data_to_register;
------------------------------------------------------------------------
    function read_data_from_register
    (
        address : integer
    )
    return base_array
    is
    begin
        return int_to_bytes(address);
    end read_data_from_register;
------------------------------------------------------------------------
    function get_command
    (
        uart_communcation_object : uart_communcation_record
    )
    return integer
    is
    begin
        return to_integer(unsigned(uart_communcation_object.receive_buffer(0)));
    end get_command;
------------------------------------------------------------------------
    function get_command_address
    (
        uart_communcation_object : uart_communcation_record
    )
    return integer
    is
    begin
        return bytes_to_int(uart_communcation_object.receive_buffer(1 to 2));
    end get_command_address;
------------------------------------------------------------------------
    function get_command_data
    (
        uart_communcation_object : uart_communcation_record
    )
    return integer
    is
    begin
        return bytes_to_int(uart_communcation_object.receive_buffer(3 to 4));
    end get_command_data;
------------------------------------------------------------------------
    function get_number_of_registers_to_stream
    (
        uart_communication_object : uart_communcation_record
    )
    return integer
    is
        alias data is uart_communication_object.receive_buffer;
    begin
        return to_integer(unsigned(data(3)) & unsigned(data(4))& unsigned(data(5)));

    end get_number_of_registers_to_stream;
------------------------------------------------------------------------
    function transmit_is_ready
    (
        uart_communication_object : uart_communcation_record
    )
    return boolean
    is
    begin
        return uart_communication_object.is_ready;
    end transmit_is_ready;
------------------------------------------------------------------------
end package body uart_communication_pkg;
