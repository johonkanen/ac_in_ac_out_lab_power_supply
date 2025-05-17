library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package measurement_pkg is
    -- generic(
    --     package meas_ram_pkg is new work.ram_port_generic_pkg generic map(<>)
    -- );

    type measurement_in_record is record 
        sample_llc : boolean;
        sample_dhb : boolean;
        sample_a   : boolean;
        sample_b   : boolean;
        next_sampled_a_channel : natural range 0 to 7;
        next_sampled_b_channel : natural range 0 to 7;
    end record;

    constant init_measurement_in : measurement_in_record := (false, false, false, false, 0, 0);

    -- type measurement_out_record is record
    --     a_sample_and_hold_ready : boolean;
    --     b_sample_and_hold_ready : boolean;
    -- end record;

end package measurement_pkg;
-------------------
package body measurement_pkg is

    procedure init_measurement(signal self_in : out measurement_in_record) is
    begin
        self_in.sample_llc <= false;
        self_in.sample_dhb <= false;
        self_in.sample_a   <= false;
        self_in.sample_b   <= false;
    end procedure;

    procedure sample_llc(signal self_in : inout measurement_in_record) is
    begin
        self_in.sample_llc <= true;
    end procedure;

    procedure sample_dhb(signal self_in : inout measurement_in_record) is
    begin
        self_in.sample_dhb <= true;
    end procedure;

end package body;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.measurement_pkg.all;

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
        ;ram_b_in              : out meas_ram_pkg.ram_in_record
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
    constant ad_channels : ad_array(0 to 6)    := (0=> 2 , 1 => 1 , 2=> 0 , 3=> 3 , 4=> 4 , 5=> 6 , 6 => 7);
    constant mux_to_channel : ad_array(0 to 7) := (0=> 2 , 1 => 1 , 2=> 0 , 3=> 3 , 4=> 4 , 5=> 5 , 6=> 5 , 7=> 6);

    signal next_mux_pos : natural range 0 to 7 := 0;
    signal mux_pos : std_logic_vector(15 downto 0) := (others => '0');

    signal sampled_a_mux : natural range 0 to 7 := 0;
    signal sampled_b_mux : natural range 0 to 7 := 0;

    signal adb_sh_timer : natural range 0 to 127 := 127;
    constant sh_max     : natural := 16;

    signal adb_timer : natural range 0 to 63 := 0;

    ----------------
    function to_integer(a : std_logic_vector) return natural is
    begin
        return to_integer(unsigned(a));
    end to_integer;
    ----------------

    constant multiplier_word_length : integer := 24;
    package multiplier_pkg is new work.multiplier_generic_pkg 
        generic map(multiplier_word_length, 1, 1);

    use multiplier_pkg.all;
    signal multiplier : multiplier_record := init_multiplier;

    -- not calibrated
    constant measurement_gains : real_vector :=
    (
         0 => 7.279/4095.0 -- vllc_gain
        ,1 => 1.0         -- vllc_offset

        ,2 => 16.5/2048.0 -- illc_gain
        ,3 => 2.0         -- illc_offset

        ,4 => 660.0/4095.0 -- vdhb_gain
        ,5 => 3.0          -- vdhb_offset
        
        ,6 => 16.5/2048.0 -- idhb_gain
        ,7 => 4.0         -- idhb_offset

        ,8 => 660.0/2048.0 -- vac_gain
        ,9 => 5.0          -- vac_offset

        ,10 => 16.5/2048.0 -- iac1_gain
        ,11 => 6.0         -- iac1_offset

        ,12 => 16.5/2048.0 -- iac2_gain
        ,13 => 7.0         -- iac2_offset

        ,14 => 663.0/4095.0 -- vdc_gain
        ,15 => 8.0          -- vdc_offset

        ,16 => 663.0/4095.0 -- vaux_gain
        ,17 => 9.0          -- vaux_offset
    );

    --                            ext2 , adb2 , ext1 , adb6 , adb1 , adb3 , ada3 , adb4 , ada5 ,
    type list_of_measurements is (vllc , illc , vdhb , idhb , vac  , iac1 , iac2 , vdc  , vaux, nothing);
    type measurement_indices is array (list_of_measurements'range) of natural;

    -- constant adb_mux_positions : measurement_indices := (
    --     vllc  => 16
    --     ,illc => 2
    --     ,vdhb => 16
    --     ,idhb => 6
    --     ,vac  => 1
    --     ,iac1 => 3
    --     ,iac2 => 16
    --     ,vdc  => 4
    --     ,vaux => 16
    --     ,nothing => 16);

    -- constant ada_mux_positions : measurement_indices := (
    --     vllc  => 16
    --     ,illc => 16
    --     ,vdhb => 16
    --     ,idhb => 16
    --     ,vac  => 16
    --     ,iac1 => 16
    --     ,iac2 => 3
    --     ,vdc  => 16
    --     ,vaux => 5
    --     ,nothing => 16);

    signal scaling_state_count : natural := 0;

    signal converted_measurement  : list_of_measurements := nothing;
    type list_of_measurements_array is array (natural range <>) of list_of_measurements;
    signal measurement_pipeline : list_of_measurements_array(4 downto 0) := (others => nothing);

    signal ram_busy : boolean := false;
    signal offset_addr : natural range 0 to 31 := 0;

    constant vllc_gain_addr   : natural := 0;
    constant vllc_offset_addr : natural := 1;
    constant illc_gain_addr   : natural := 2;
    constant illc_offset_addr : natural := 3;
    constant vdhb_gain_addr   : natural := 4;
    constant vdhb_offset_addr : natural := 5;
    constant idhb_gain_addr   : natural := 6;
    constant idhb_offset_addr : natural := 7;
    constant vac_gain_addr    : natural := 8;
    constant vac_offset_addr  : natural := 9;
    constant iac1_gain_addr   : natural := 10;
    constant iac1_offset_addr : natural := 11;
    constant iac2_gain_addr   : natural := 12;
    constant iac2_offset_addr : natural := 13;
    constant vdc_gain_addr    : natural := 14;
    constant vdc_offset_addr  : natural := 15;
    constant vaux_gain_addr   : natural := 16;
    constant vaux_offset_addr : natural := 17;

    use work.real_to_fixed_pkg.all;

    package dp_ram_pkg is new work.ram_port_generic_pkg generic map(g_ram_bit_width => multiplier_word_length , g_ram_depth_pow2 => 6);
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

    signal ad_conversion      : mpy_signed;
    signal offset             : mpy_signed;
    signal scaled_measurement : mpy_signed;

    signal result_ready      : boolean := false;

    signal ram_load_state_counter : natural := 0;

    signal scaling_requested : boolean := false;
    signal scaling_pipeline : std_logic_vector(4 downto 0) := (others => '0');

    signal pong : boolean := false;

begin

    ada_mux <= mux_pos(2 downto 0);
    adb_mux <= mux_pos(2 downto 0);

    -----------------------------------------------------
    ram_writer : process(clock)
    begin
        if rising_edge(clock)
        then
            init_ram(ram_b_in);

            ada_ready <= ada_ready or ad_conversion_is_ready(ada);
            adb_ready <= adb_ready or ad_conversion_is_ready(adb);
            dhb_ready <= dhb_ready or ad_conversion_is_ready(dab_adc);
            llc_ready <= llc_ready or ad_conversion_is_ready(llc_adc);

            pong <= false;
            if measurement_pipeline(3) /= nothing
            then
                write_data_to_ram(ram_b_in, list_of_measurements'pos(measurement_pipeline(3))+20, std_logic_vector(scaled_measurement(ram_b_in.data'range)));
                pong <= true;

            elsif ad_conversion_is_ready(adb) or adb_ready
            then
                adb_ready <= false;
                write_data_to_ram(ram_b_in , sampled_b_mux + 8 , get_converted_measurement(adb));

            elsif ad_conversion_is_ready(ada) or ada_ready 
            then
                ada_ready <= false;
                write_data_to_ram(ram_b_in , sampled_a_mux , get_converted_measurement(ada));

            elsif ad_conversion_is_ready(dab_adc) or dhb_ready 
            then
                dhb_ready <= false;
                write_data_to_ram(ram_b_in , 16 , get_converted_measurement(dab_adc));

            elsif ad_conversion_is_ready(llc_adc) or llc_ready 
            then
                llc_ready <= false;
                write_data_to_ram(ram_b_in , 17 , get_converted_measurement(llc_adc));
            end if;

        end if;
    end process ram_writer;
    -----------------------------------------------------
    process(clock)
    begin
        if rising_edge(clock)
        then
            init_bus(bus_from_measurements);
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 2  , get_converted_measurement(ada));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 3  , get_converted_measurement(adb));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 4  , get_converted_measurement(dab_adc));
            connect_read_only_data_to_address(bus_to_measurements , bus_from_measurements , 5  , get_converted_measurement(llc_adc));

            create_max11115(ada , ada_data , ada_cs , ada_clock);
            create_max11115(adb , adb_data , adb_cs , adb_clock);

            create_max11115(dab_adc , dab_spi_data , dab_spi_cs , dab_spi_clock , offset => 1);
            create_max11115(llc_adc , llc_spi_data , llc_spi_cs , llc_spi_clock , offset => 1);

            ------------------------------------------
            if count_to_800khz < counter_max_800kHz 
            then
                count_to_800khz <= count_to_800khz + 1;
            else
                count_to_800khz <= 0;
            end if;

            if count_to_800khz = 0 
            then
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

                sampled_a_mux <= mux_to_channel(to_integer(unsigned(ada_mux)));
                sampled_b_mux <= mux_to_channel(to_integer(unsigned(adb_mux)));

            end if;

            if adb_sh_timer < sh_max
            then
                adb_sh_timer <= adb_sh_timer + 1;
            end if;

            if (adb_sh_timer = sh_max - 1)
            then
                next_mux_pos <= 3;

                mux_pos(2 downto 0) <= std_logic_vector(to_unsigned(ad_channels(next_mux_pos), 3));

            end if;

        end if;
    end process;

    -----------------------------------------------------
    retrieve_gains : process(clock) is
    begin
        if rising_edge(clock)
        then
            init_ram(meas_ram_b_in);

            ada_ready_for_scaling <= ada_ready_for_scaling or ad_conversion_is_ready(ada);
            adb_ready_for_scaling <= adb_ready_for_scaling or ad_conversion_is_ready(adb);
            dhb_ready_for_scaling <= dhb_ready_for_scaling or ad_conversion_is_ready(dab_adc);
            llc_ready_for_scaling <= llc_ready_for_scaling or ad_conversion_is_ready(llc_adc);
            ram_busy <= false;
            converted_measurement <= nothing;

            scaling_requested <= false;
            CASE ram_load_state_counter is
                WHEN 0 =>

                if (ad_conversion_is_ready(adb) or adb_ready_for_scaling)
                then
                    ram_load_state_counter <= ram_load_state_counter+1;
                    adb_ready_for_scaling  <= false;
                    ad_conversion          <= resize(signed(get_converted_measurement(adb)),mpy_signed'length);
                    scaling_requested <= true;

                    CASE sampled_b_mux is
                        WHEN 1 =>  -- vac
                            converted_measurement <= vac;
                            request_data_from_ram(meas_ram_b_in , 8);
                            offset_addr <= 9;
                        WHEN 2 =>  -- illc
                            converted_measurement <= illc;
                            request_data_from_ram(meas_ram_b_in , 2);
                            offset_addr <= 3;
                        WHEN 3 =>  -- iac1
                            converted_measurement <= iac1;
                            request_data_from_ram(meas_ram_b_in , 10);
                            offset_addr <= 11;
                        WHEN 4 =>  -- vdc
                            converted_measurement <= vdc;
                            request_data_from_ram(meas_ram_b_in , 14);
                            offset_addr <= 15;
                        WHEN 6 =>  -- idhb
                            converted_measurement <= idhb;
                            request_data_from_ram(meas_ram_b_in , 4);
                            offset_addr <= 5;
                        when others => --do nothing
                    end CASE;

                elsif (ad_conversion_is_ready(ada) or ada_ready_for_scaling)
                then
                    ram_load_state_counter <= ram_load_state_counter+1;
                    ada_ready_for_scaling  <= false;
                    ad_conversion          <= resize(signed(get_converted_measurement(adb)),mpy_signed'length);
                    scaling_requested <= true;

                    CASE sampled_a_mux is
                        WHEN 3 =>  -- iac2
                            converted_measurement <= iac2;
                            request_data_from_ram(meas_ram_b_in , 12);
                            offset_addr <= 13;
                        WHEN 5 =>  -- vaux
                            converted_measurement <= vaux;
                            request_data_from_ram(meas_ram_b_in , 16);
                            offset_addr <= 17;
                        when others => --do nothing
                    end CASE;

                elsif (ad_conversion_is_ready(dab_adc) or dhb_ready_for_scaling)
                then
                    ram_load_state_counter <= ram_load_state_counter+1;
                    dhb_ready_for_scaling <= false;
                    ad_conversion         <= resize(signed(get_converted_measurement(adb)),mpy_signed'length);
                    scaling_requested <= true;

                    request_data_from_ram(meas_ram_b_in , vdhb_gain_addr);
                    offset_addr <= vdhb_offset_addr;
                    converted_measurement <= vdhb;

                elsif (ad_conversion_is_ready(llc_adc) or llc_ready_for_scaling)
                then
                    ram_load_state_counter <= ram_load_state_counter+1;
                    llc_ready_for_scaling <= false;
                    ad_conversion         <= resize(signed(get_converted_measurement(adb)),mpy_signed'length);
                    converted_measurement <= vllc;
                    scaling_requested <= true;

                    request_data_from_ram(meas_ram_b_in , vllc_gain_addr);
                    offset_addr <= vdhb_offset_addr;
                end if;
            WHEN 1 =>
                ram_load_state_counter <= 0;
                request_data_from_ram(meas_ram_b_in, offset_addr);
            WHEN others => ram_load_state_counter <= 0;

            end CASE;

        end if; -- rising edge
    end process retrieve_gains;

    ---------------------------------------------------
    scaling : process(clock) is
    begin
        if rising_edge(clock)
        then
            create_multiplier(multiplier);
            init_ram(meas_ram_a_in);
            scaling_pipeline <= scaling_pipeline(scaling_pipeline'left-1 downto 0) & '0';
            measurement_pipeline <= measurement_pipeline(measurement_pipeline'left-1 downto 0) & converted_measurement;
            if scaling_requested then 
                scaling_pipeline(0) <= '1'; 
            end if;

            if scaling_pipeline(1) then
                multiply(multiplier, ad_conversion, signed(get_ram_data(meas_ram_b_out)));
            end if;

            if scaling_pipeline(2) then
                offset <= resize(signed(get_ram_data(meas_ram_b_out)), offset'length);
            end if;

            result_ready <= false;
            if scaling_pipeline(3) then
                scaled_measurement <= get_multiplier_result(multiplier, 0, multiplier_word_length, 15) + offset;
                result_ready <= true;
            end if;

        end if;
    end process scaling;
    -----------------------------------------------------
    u_dpram : entity work.generic_dual_port_ram
    generic map(dp_ram_pkg, ram_init_values)
    port map(
    clock          ,
    meas_ram_a_in  ,
    meas_ram_a_out ,
    --------------
    meas_ram_b_in  ,
    meas_ram_b_out);

end rtl;
------------------------------------------------
