
---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity ecp5_top is
    port (
        xclock : in std_logic

        ;uart_rx : in std_logic
        ;uart_tx : out std_logic
    );
end entity ecp5_top;

architecture rtl of ecp5_top is

begin

    uart_tx <= uart_rx;

end rtl;
