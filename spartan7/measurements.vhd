
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

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

    package adc121s101_pkg is new work.max11115_generic_pkg generic map (g_count_max => 7);
        use adc121s101_pkg.all;

    signal dab_adc : max11115_record := init_max11115;
    signal llc_adc : max11115_record := init_max11115;
    constant counter_max_800kHz : natural := 128e6/930e3;
    signal count_to_800khz : natural range 0 to 1000 := 0;

    package max11115_pkg is new work.max11115_generic_pkg generic map(g_count_max => 3);
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

    -- not calibrated
    constant measurement_gains : real_vector :=
    (
        7.279/4095.0 -- vllc_gain
        ,0.0         -- vllc_offset

        ,16.5/2048.0 -- illc_gain
        ,0.0         -- illc_offset

        ,660.0/4095.0 -- vdhb_gain
        ,0.0          -- vdhb_offset
        
        ,16.5/2048.0 -- idhb_gain
        ,0.0         -- idhb_offset

        ,660.0/2048.0 -- vac_gain
        ,0.0          -- vac_offset

        ,16.5/2048.0 -- iac1_gain
        ,0.0         -- iac1_offset

        ,16.5/2048.0 -- iac2_gain
        ,0.0         -- iac2_offset

        ,663.0/4095.0 -- vdc_gain
        ,0.0          -- vdc_offset

        ,663.0/4095.0 -- vaux_gain
        ,0.0          -- vaux_offset
    );

    use work.real_to_fixed_pkg.all;

    package dp_ram_pkg is new work.ram_port_generic_pkg generic map(g_ram_bit_width => multiplier_word_length, g_ram_depth_pow2 => 5);
    use dp_ram_pkg.all;

    function ram_init_values return dp_ram_pkg.ram_array is
        variable retval : dp_ram_pkg.ram_array := (others => (others => '0'));
    begin
        for i in 0 to 17 loop
            retval(i) := to_fixed(measurement_gains(i) , multiplier_word_length , multiplier_word_length);
        end loop;

        return retval;
    end function ram_init_values;

    signal meas_ram_a_in : dp_ram_pkg.ram_in_record;
    signal meas_ram_b_in : dp_ram_pkg.ram_in_record;

    signal meas_ram_a_out : dp_ram_pkg.ram_out_record;
    signal meas_ram_b_out : dp_ram_pkg.ram_out_record;

    signal ada_ready : boolean := false;
    signal adb_ready : boolean := false;
    signal dhb_ready : boolean := false;
    signal llc_ready : boolean := false;

    signal ada_ready_for_scaling : boolean := false;
    signal adb_ready_for_scaling : boolean := false;
    signal dhb_ready_for_scaling : boolean := false;
    signal llc_ready_for_scaling : boolean := false;

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

            create_max11115(ada , ada_data , ada_cs , ada_clock);
            create_max11115(adb , adb_data , adb_cs , adb_clock);

            create_max11115(dab_adc , dab_spi_data , dab_spi_cs , dab_spi_clock , offset => 1);
            create_max11115(llc_adc , llc_spi_data , llc_spi_cs , llc_spi_clock , offset => 1);

            ------------------------------------------
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

            if adb_timer < 41
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

            ada_ready <= ada_ready or ad_conversion_is_ready(ada);
            adb_ready <= adb_ready or ad_conversion_is_ready(adb);
            dhb_ready <= dhb_ready or ad_conversion_is_ready(dab_adc);
            llc_ready <= llc_ready or ad_conversion_is_ready(llc_adc);

            if ad_conversion_is_ready(adb) or adb_ready
            then
                adb_ready <= false;
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) , get_converted_measurement(adb));

            elsif ad_conversion_is_ready(ada) or ada_ready 
            then
                ada_ready <= false;
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) + 8 , get_converted_measurement(ada));

            elsif ad_conversion_is_ready(dab_adc) or dhb_ready 
            then
                dhb_ready <= false;
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) + 16 , get_converted_measurement(ada));

            elsif ad_conversion_is_ready(llc_adc) or llc_ready 
            then
                llc_ready <= false;
                write_data_to_ram(ram_b_in , to_integer(unsigned(mux_pos(2 downto 0))) + 17 , get_converted_measurement(ada));
            end if;

        end if;
    end process;

-------------------------
    scaling : process(clock) is
    begin
        if rising_edge(clock)
        then
            create_multiplier(multiplier);
            init_ram(meas_ram_a_in);
            init_ram(meas_ram_b_in);

            ada_ready_for_scaling <= ada_ready_for_scaling or ad_conversion_is_ready(ada);
            adb_ready_for_scaling <= adb_ready_for_scaling or ad_conversion_is_ready(adb);
            dhb_ready_for_scaling <= dhb_ready_for_scaling or ad_conversion_is_ready(dab_adc);
            llc_ready_for_scaling <= llc_ready_for_scaling or ad_conversion_is_ready(llc_adc);


        end if;
    end process scaling;
-------------------------
    u_dpram : entity work.generic_dual_port_ram
    generic map(dp_ram_pkg)
    port map(
    clock          ,
    meas_ram_a_in  ,
    meas_ram_a_out ,
    --------------
    meas_ram_b_in  ,
    meas_ram_b_out);
-------------------------
end rtl;
------------------------------------------------
