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

    constant init_uart_stream : uart_stream_record := (5, false , false , false);

end package uart_stream_pkg;

package body uart_stream_pkg is

    procedure create_uart_stream
    (
        signal uart_stream_object : inout uart_stream_record;
        signal uart_communication_object : inout uart_communcation_record
    ) is
        alias m is uart_stream_object;
    begin

        if transmit_is_ready(uart_communication_object) then
            if m.stream_counter > 0 then
                m.stream_counter <= m.stream_counter - 1;
                send_stream_data_packet(uart_communication_object, (x"ac", x"dc"));
            end if;
        end if;
        
    end create_uart_stream;

end package body uart_stream_pkg;
