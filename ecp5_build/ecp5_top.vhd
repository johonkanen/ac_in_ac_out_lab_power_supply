
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

    component main_pll
        port (
             CLKI: in  std_logic
            ; CLKOP: out  std_logic);
    end component;

    signal main_clock_120MHz : std_logic := '0';

begin

    u_main_pll : main_pll
    port map (
         CLKI    => xclock
         , CLKOP => main_clock_120MHz
     );

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            uart_tx <= uart_rx;
        end if;
    end process;

end rtl;
