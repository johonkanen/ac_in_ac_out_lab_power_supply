library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

--- 
entity test_crash is
    generic(g_ram_bit_width : positive
            ;g_ram_depth_pow2 : positive
           );
    port (
        main_clock : in std_logic
    );
end entity test_crash;

architecture test of test_crash is

    package ram_port_pkg is new work.ram_port_generic_pkg 
        generic map(
            g_ram_bit_width    => g_ram_bit_width
            , g_ram_depth_pow2 => g_ram_depth_pow2);

    use ram_port_pkg.all;

    signal ram_a_in  : ram_in_record;
    signal ram_a_out : ram_out_record;
    --------------------
    signal ram_b_in  : ram_in_record;
    signal ram_b_out : ram_out_record;

begin
    u_dpram : entity work.generic_dual_port_ram
    generic map(ram_port_pkg)
    port map(
    main_clock ,
    ram_a_in   ,
    ram_a_out  ,
    --------------
    ram_b_in  ,
    ram_b_out);
------------------------------------------------------------------------
end test;


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
    u_test_crash : entity work.test_crash
    generic map(20, 10)
    port map(
    main_clock);

------------------------------------------------------------------------
end rtl;
