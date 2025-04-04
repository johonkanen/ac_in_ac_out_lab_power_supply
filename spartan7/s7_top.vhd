
-------------------------------------------------------------------
---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity s7_top is
    port (
        xclk : in std_logic

        ;uart_rx : in std_logic
        ;uart_tx : out std_logic

        ;ada_mux   : out std_logic_vector(0 to 2)
        ;ada_clock : out std_logic
        ;ada_cs    : out std_logic
        ;ada_data  : in std_logic

        ;adb_mux   : out std_logic_vector(0 to 2)
        ;adb_clock : out std_logic
        ;adb_cs    : out std_logic
        ;adb_data  : in std_logic

        ;rgb_led1   : out std_logic_vector(2 downto 0)
        ;rgb_led2   : out std_logic_vector(2 downto 0)
        ;rgb_led3   : out std_logic_vector(2 downto 0)
    );
end entity s7_top;

architecture rtl of s7_top is
    
    package dp_ram_pkg is new work.ram_port_generic_pkg generic map(g_ram_bit_width => 16, g_ram_depth_pow2 => 10);
    use dp_ram_pkg.all;

    package interconnect_pkg is new work.fpga_interconnect_generic_pkg 
        generic map(number_of_data_bits => 16,
                 number_of_address_bits => 16);

    use interconnect_pkg.all;


    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal main_clock_120MHz : std_logic := '0';

    signal led_blink_counter : natural range 0 to 120e6;
    signal led_state : std_logic := '0';

    package max11115_pkg is new work.max11115_generic_pkg;
        use max11115_pkg.all;
    signal ada : max11115_record := init_max11115;
    signal adb : max11115_record := init_max11115;
    component main_pll
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;

    subtype t_ad_channels is natural range 0 to 7;
    type ad_array is array (natural range <>) of t_ad_channels;
    constant ad_channels : ad_array(0 to 6) := (2,1,0,3,4,6,7);

    signal ram_a_in : ram_in_record;
    signal ram_b_in : ram_in_record;

    signal ram_a_out : ram_out_record;
    signal ram_b_out : ram_out_record;

    signal next_mux_pos : natural range 0 to 7 := 0;
    signal mux_pos : std_logic_vector(15 downto 0) := (others => '0');

    function to_integer(a : std_logic_vector) return natural is
    begin
        return to_integer(unsigned(a));
    end to_integer;

    signal adb_sh_timer : natural range 0 to 127 := 127;
    constant sh_max     : natural := 16;

    signal adb_timer : natural range 0 to 63 := 0;

begin

    rgb_led1(0) <= led_state;

    ada_mux <= mux_pos(2 downto 0);
    adb_mux <= mux_pos(2 downto 0);

    u_main_pll : main_pll
    port map (
         clk_in1    => xclk
         , clk_out1 => main_clock_120MHz
     );

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            init_bus(bus_to_communications);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 1 , 44252);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 2 , get_converted_measurement(ada));
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 3 , get_converted_measurement(adb));

            create_max11115(ada , ada_data , ada_cs , ada_clock);
            create_max11115(adb , adb_data , adb_cs , adb_clock);

            if led_blink_counter < 60e6 
            then
                led_blink_counter <= led_blink_counter + 1;
            else
                led_blink_counter <= 0;
            end if;

            if adb_timer < 63
            then
                adb_timer <= adb_timer + 1;
            else
                adb_timer <= 0;
            end if;

            if (adb_timer = 0)
            then
                request_conversion(ada);
                request_conversion(adb);
                adb_sh_timer <= 0;
            end if;

            if adb_sh_timer < sh_max
            then
                adb_sh_timer <= adb_sh_timer + 1;
            end if;

            if (adb_sh_timer = sh_max - 1)
            then
                if next_mux_pos < 6
                then
                    next_mux_pos <= next_mux_pos + 1;
                else
                    next_mux_pos <= 0;
                end if;

                mux_pos(2 downto 0) <= std_logic_vector(to_unsigned(ad_channels(next_mux_pos), 3));

            end if;

            if led_blink_counter = 0 
            then
                led_state <= not led_state;
            end if;

            init_ram(ram_a_in);
            init_ram(ram_b_in);

            if ad_conversion_is_ready(adb)
            then
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) , get_converted_measurement(adb));
            end if;

            if data_is_requested_from_address_range(bus_from_communications, 1000, 1007) then
                request_data_from_ram(ram_a_in, get_address(bus_from_communications) - 1000);
            end if;

            if ram_read_is_ready(ram_a_out)
            then
                write_data_to_address(bus_to_communications, 0, get_ram_data(ram_a_out));
            end if;

        end if;
    end process;

---------------
    u_dpram : entity work.generic_dual_port_ram
    generic map(dp_ram_pkg)
    port map(
    main_clock_120MHz ,
    ram_a_in   ,
    ram_a_out  ,
    --------------
    ram_b_in  ,
    ram_b_out);

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
