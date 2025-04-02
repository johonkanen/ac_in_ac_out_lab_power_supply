---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity ecp5_top is
    port (
        xclock : in std_logic

        ;uart_rx : in std_logic
        ;uart_tx : out std_logic

        ;rgb1_r : out std_logic
    );
end entity ecp5_top;

architecture rtl of ecp5_top is

    package interconnect_pkg is new work.fpga_interconnect_generic_pkg 
        generic map(number_of_data_bits => 16,
                 number_of_address_bits => 16);

    use interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    component main_pll
        port (
            CLKI    : in  std_logic
            ; CLKOP : out  std_logic);
    end component;

    signal main_clock_120MHz : std_logic := '0';

    signal led_blink_counter : natural range 0 to 120e6;
    signal led_state : std_logic := '0';

begin

    rgb1_r <= led_state;

    u_main_pll : main_pll
    port map (
         CLKI    => xclock
         , CLKOP => main_clock_120MHz
     );

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            init_bus(bus_to_communications);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 1 , 44252);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 2 , 37);

            if led_blink_counter < 60e6 then
                led_blink_counter <= led_blink_counter + 1;
            else
                led_blink_counter <= 0;
            end if;

            if led_blink_counter = 0 then
                led_state <= not led_state;
            end if;


        end if;
    end process;

------------------------------------------------------------------------
    u_fpga_communications : entity work.fpga_communications
    generic map(interconnect_pkg, g_clock_divider => 24)
        port map(
            clock                    => main_clock_120MHz
            ,uart_rx                 => uart_rx
            ,uart_tx                 => uart_tx
            ,bus_to_communications   => bus_to_communications
            ,bus_from_communications => bus_from_communications
        );
------------------------------------------------------------------------

end rtl;
