library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity titanium_top is
    port (
        main_clock : in std_logic
        -- leds         : out std_logic_vector(3 downto 0)
    );
end entity titanium_top;

architecture rtl of titanium_top is

    use work.fpga_interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_top : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_signal_scope : fpga_interconnect_record := init_fpga_interconnect;
    signal trigger_event : boolean;
    signal sampled_data : std_logic_vector(15 downto 0);
    signal test_counter : natural := 0;


begin

------------------------------------------------------------------------
    u_signal_scope : entity work.signal_scope
        generic map( 16, 8)
        port map(
            main_clock
            ,bus_from_communications
            ,bus_from_signal_scope
            ,trigger_event
            ,true
            ,sampled_data
        );

    sampled_data <= std_logic_vector(to_unsigned(test_counter, 16));
    trigger_event <= test_counter = 3e3;
    test_counter <= test_counter + 1 when rising_edge(main_clock);

------------------------------------------------------------------------
end rtl;
