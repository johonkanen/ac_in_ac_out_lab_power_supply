
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity measurements is
    generic(
        package fpga_interconnect_pkg is new work.fpga_interconnect_generic_pkg generic map(<>)
        ;package meas_ram_pkg is new work.ram_port_generic_pkg generic map(<>)
     );
    port (
        clock : in std_logic
        ;ada_mux   : out std_logic_vector(0 to 2)
        ;ada_clock : out std_logic
        ;ada_cs    : out std_logic
        ;ada_data  : in std_logic

        ;adb_mux   : out std_logic_vector(0 to 2)
        ;adb_clock : out std_logic
        ;adb_cs    : out std_logic
        ;adb_data  : in std_logic

        ;dab_spi_clock : out std_logic
        ;dab_spi_cs    : out std_logic
        ;dab_spi_data  : in std_logic

        ;llc_spi_clock : out std_logic
        ;llc_spi_cs    : out std_logic
        ;llc_spi_data  : in std_logic

        ;bus_to_measurements   : in fpga_interconnect_pkg.fpga_interconnect_record
        ;bus_from_measurements : out fpga_interconnect_pkg.fpga_interconnect_record
        ;ram_b_in : out meas_ram_pkg.ram_in_record
    );
end entity measurements;

architecture rtl of measurements is

    use fpga_interconnect_pkg.all;
    use meas_ram_pkg.all;

    package adc121s101_pkg is new work.max11115_generic_pkg(g_count_max => 7);
        use adc121s101_pkg.all;

    signal dab_adc : max11115_record := init_max11115;
    signal llc_adc : max11115_record := init_max11115;
    constant counter_max_800kHz : natural := 128e6/800e3;
    signal count_to_800khz : natural range 0 to 1000 := 0;

    package max11115_pkg is new work.max11115_generic_pkg;
        use max11115_pkg.all;
    signal ada : max11115_pkg.max11115_record := max11115_pkg.init_max11115;
    signal adb : max11115_pkg.max11115_record := max11115_pkg.init_max11115;

    subtype t_ad_channels is natural range 0 to 7;
    type ad_array is array (natural range <>) of t_ad_channels;
    constant ad_channels : ad_array(0 to 6) := (2,1,0,3,4,6,7);

    signal next_mux_pos : natural range 0 to 7 := 0;
    signal mux_pos : std_logic_vector(15 downto 0) := (others => '0');

    signal adb_sh_timer : natural range 0 to 127 := 127;
    constant sh_max     : natural := 16;

    signal adb_timer : natural range 0 to 63 := 0;

    ----------------
    function to_integer(a : std_logic_vector) return natural is
    begin
        return to_integer(unsigned(a));
    end to_integer;
    ----------------

    constant multiplier_word_length : integer := 25;
    package multiplier_pkg is new work.multiplier_generic_pkg 
        generic map(multiplier_word_length, 2, 2);
    use multiplier_pkg.all;
    signal multiplier : multiplier_record := init_multiplier;


    constant llc_gain   : real := 7.279/4095.0; -- not calibrated
    constant llc_offset : real := 0.0;

    constant dhb_gain   : real := 660.0/4095;   -- not calibrated
    constant dhb_offset : real := 0.0;

    constant vac_gain   : real := 660.0/4095; -- not calibrated!!!
    constant vac_offset : real := 0.0;

    constant iac1_gain   : real := 16.5/2048;  -- not calibrated
    constant iac1_offset : real := 0.0;

    constant iac2_gain   : real := 16.5/2048;  -- not calibrated
    constant iac2_offset : real := 0.0;

    constant vdc_gain   : real := 663.0/4095;  -- not calibrated
    constant vdc_offset : real := 0.0;

    constant vaux_gain   : real := 663.0/4095;  -- not calibrated
    constant vaux_offset : real := 0.0;

    constant idab_gain   : real := 16.5/2048;  -- not calibrated
    constant idab_offset : real := 0.0;

    constant illc_gain   : real := 16.5/2048;  -- not calibrated
    constant illc_offset : real := 0.0;

begin

    ada_mux <= mux_pos(2 downto 0);
    adb_mux <= mux_pos(2 downto 0);

    process(clock)
    begin
        if rising_edge(clock)
        then
            init_bus(bus_from_measurements);
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 10 , 66);
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 2  , get_converted_measurement(ada));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 3  , get_converted_measurement(adb));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 4  , get_converted_measurement(dab_adc));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 5  , get_converted_measurement(llc_adc));


            create_max11115(dab_adc , dab_spi_data , dab_spi_cs , dab_spi_clock, offset => 1);
            create_max11115(llc_adc , llc_spi_data , llc_spi_cs , llc_spi_clock, offset => 1);

            if count_to_800khz < counter_max_800kHz then
                count_to_800khz <= count_to_800khz + 1;
            else
                count_to_800khz <= 0;
            end if;

            if count_to_800khz = 0 then
                request_conversion(dab_adc);
                request_conversion(llc_adc);
            end if;
            ------------------------------------------

            create_max11115(ada , ada_data , ada_cs , ada_clock);
            create_max11115(adb , adb_data , adb_cs , adb_clock);

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

            init_ram(ram_b_in);

            if ad_conversion_is_ready(adb)
            then
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) , get_converted_measurement(adb));
            end if;


        end if;
    end process;

-------------------------
    scaling : process(clock) is
    begin
        if rising_edge(clock)
        then
            create_multiplier(multiplier);

        end if;
    end process scaling;
-------------------------
end rtl;
------------------------------------------------
