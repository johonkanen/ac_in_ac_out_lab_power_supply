library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.uart_communication_pkg.all;

package uart_stream_pkg is

    type uart_stream_record is record
        stream_counter       :  integer range 0 to 15;
        streaming_is_ongoing :  boolean              ;
        stream_is_ready      :  boolean              ;
        transmit_is_done     :  boolean              ;
    end record;

    constant init_uart_stream : uart_stream_record := (0, false , false , false);

------------------------------------------------------------------------
    procedure create_uart_stream (
        signal uart_stream_object : inout uart_stream_record;
        signal uart_communication_object : inout uart_communcation_record);
------------------------------------------------------------------------
    procedure set_number_of_transmitted_streams (
        signal uart_stream_object : out uart_stream_record;
        number_of_streams         : in integer);
------------------------------------------------------------------------
    function uart_stream_is_ready ( uart_stream_object : uart_stream_record)
        return boolean;
------------------------------------------------------------------------
end package uart_stream_pkg;

package body uart_stream_pkg is

------------------------------------------------------------------------
    procedure create_uart_stream
    (
        signal uart_stream_object : inout uart_stream_record;
        signal uart_communication_object : inout uart_communcation_record
    ) is
        alias m is uart_stream_object;
    begin

        m.stream_is_ready <= false;
        m.streaming_is_ongoing <= m.stream_counter > 0;
        if transmit_is_ready(uart_communication_object) then
            if m.stream_counter > 0 then
                m.stream_counter <= m.stream_counter - 1;
                send_stream_data_packet(uart_communication_object, (x"ac", x"dc"));
            else
                m.stream_is_ready      <= true;
                m.streaming_is_ongoing <= false;
            end if;
        end if;

        
    end create_uart_stream;
------------------------------------------------------------------------
    function uart_stream_is_ready
    (
        uart_stream_object : uart_stream_record
    )
    return boolean
    is
    begin
        return uart_stream_object.stream_is_ready;
    end uart_stream_is_ready;
------------------------------------------------------------------------
    procedure set_number_of_transmitted_streams
    (
        signal uart_stream_object : out uart_stream_record;
        number_of_streams         : in integer
    ) is
    begin
        uart_stream_object.stream_counter <= number_of_streams;
    end set_number_of_transmitted_streams;
------------------------------------------------------------------------

end package body uart_stream_pkg;
