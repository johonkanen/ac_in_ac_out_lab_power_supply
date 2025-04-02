
-------------------------------------------------------------------
---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity s7_top is
    port (
        xclock : in std_logic

        ;uart_rx : in std_logic
        ;uart_tx : out std_logic

        ;rgb1_r : out std_logic

        -- ;ad_mux1_io           : out std_logic_vector(2 downto 0)
        ;ads_7056_clock       : out std_logic
        ;ads_7056_chip_select : out std_logic
        ;ads_7056_input_data  : in std_logic

        -- ;ad_mux2_io               : out std_logic_vector(2 downto 0)
        ;ads_7056_clock_pri       : out std_logic
        ;ads_7056_chip_select_pri : out std_logic
        ;ads_7056_input_data_pri  : in std_logic
    );
end entity s7_top;

architecture rtl of s7_top is

    package interconnect_pkg is new work.fpga_interconnect_generic_pkg 
        generic map(number_of_data_bits => 16,
                 number_of_address_bits => 16);

    use interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal main_clock_120MHz : std_logic := '0';

    signal led_blink_counter : natural range 0 to 120e6;
    signal led_state : std_logic := '0';

    use work.ads7056_pkg.all;
    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;

    component main_pll
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;

begin

    rgb1_r <= led_state;

    u_main_pll : entity work.main_pll
    port map (
         clk_in1    => xclock
         , clk_out1 => main_clock_120MHz
     );

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            init_bus(bus_to_communications);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 1 , 44252);
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 2  , get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 3  , get_converted_measurement(sec_ads7056));

            create_ads7056_driver(pri_ads7056        
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);


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
