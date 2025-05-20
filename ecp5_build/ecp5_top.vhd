-------------------------------------------------------------------
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

        -- ;ad_mux1_io           : out std_logic_vector(2 downto 0)
        ;ads_7056_clock       : out std_logic
        ;ads_7056_chip_select : out std_logic
        ;ads_7056_input_data  : in std_logic

        -- ;ad_mux2_io               : out std_logic_vector(2 downto 0)
        ;ads_7056_clock_pri       : out std_logic
        ;ads_7056_chip_select_pri : out std_logic
        ;ads_7056_input_data_pri  : in std_logic
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

    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;
    use work.real_to_fixed_pkg.all;

    use work.microprogram_pkg.all;
    signal mc_read_in       : ref_subtype.ram_read_in'subtype;
    signal mc_read_out      : ref_subtype.ram_read_out'subtype;
    signal mc_write_out     : ref_subtype.ram_write_in'subtype;

    use work.ram_connector_pkg.all;
    signal ram_connector : ram_connector_ref'subtype;

    ----
    signal ext_input        : std_logic_vector(word_length-1 downto 0) := to_fixed(-22.351, word_length, used_radix);
    signal lc_load          : std_logic_vector(word_length-1 downto 0) :=  to_fixed(0.0, word_length, used_radix);
    signal lc_duty          : std_logic_vector(word_length-1 downto 0) :=  to_fixed(0.5, word_length, used_radix);
    signal lc_input_voltage : std_logic_vector(word_length-1 downto 0) :=  to_fixed(10.0, word_length, used_radix);

    signal simcurrent : std_logic_vector(word_length-1 downto 0) :=  to_fixed(0.0, word_length, used_radix);
    signal simvoltage : std_logic_vector(word_length-1 downto 0) :=  to_fixed(0.0, word_length, used_radix);

    use work.microprogram_processor_pkg.all;

    signal mproc_in  : microprogram_processor_in_record;
    signal mproc_out : microprogram_processor_out_record;

    signal start_counter : natural range 0 to 127 := 0;

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
            -- connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 2  , get_converted_measurement(pri_ads7056));
            -- connect_read_only_data_to_address(bus_from_communications , bus_to_communications , 3  , get_converted_measurement(sec_ads7056));

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
    process(main_clock_120MHz)
    begin
        if rising_edge(main_clock_120MHz)
        then
            if start_counter > 50
            then
                start_counter <= 0;
            else
                start_counter <= start_counter + 1;
            end if;

            init_mproc(mproc_in);
            if start_counter = 0
            then
                calculate(mproc_in, 29);
            end if;

            init_ram_connector(ram_connector);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 120, ext_input);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 121, lc_load);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 122, lc_duty);
            connect_data_to_ram_bus(ram_connector, mc_read_in, mc_read_out, 123, lc_input_voltage);

            connect_ram_write_to_address(mc_write_out , inductor_current , simcurrent);
            connect_ram_write_to_address(mc_write_out , cap_voltage      , simvoltage);

        end if;
    end process;

------------------------------------------------------------------------
    u_microprogram_processor : entity work.microprogram_processor
    generic map(g_data_bit_width => word_length,g_used_radix => used_radix, g_program => test_program, g_data => program_data)
    port map(main_clock_120MHz, mproc_in, mproc_out, mc_read_in, mc_read_out, mc_write_out);
------------------------------------------------------------------------

end rtl;
