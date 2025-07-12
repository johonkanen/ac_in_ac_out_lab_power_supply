LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package meas_pkg is 

    type t_list_of_measurements is (
        vac_in        -- 0
        , vfilter_in  -- 1
        , vdc_in      -- 2
        , vdc_out     -- 3
        , vfilter_out -- 4
        , vac_out     -- 5
        , iac_in      -- 6
        , iac_out     -- 7
        , i_dab);     -- 8

    type meas_indices is array (t_list_of_measurements range t_list_of_measurements'range) of natural;
    constant meas : meas_indices := (0,1,2,3,4,5,6,7,8);
    constant mux_positions : meas_indices := (
        vac_in       => 0
        ,vfilter_in  => 3
        ,vdc_in      => 1

        ,vdc_out     => 0
        ,vfilter_out => 2
        ,vac_out     => 1

        ,iac_in      => 15   -- not muxed
        ,iac_out     => 15   -- not muxed
        ,i_dab       => 15); -- not muxed

    constant pri_input_voltage_gain   : real := 1.0/16.763636363636365;
    constant pri_input_voltage_offset : real := 8137.90909090909 * pri_input_voltage_gain;

    constant pri_dc_link_gain   : real := 1.0/16.857479572273963;
    constant pri_dc_link_offset : real := -15.196959245805374 * pri_dc_link_gain;

    constant pri_bridge_voltage_gain   : real := -1.0/16.327272727272728;
    constant pri_bridge_voltage_offset : real := 8153.272727272727 * pri_bridge_voltage_gain;

    use work.dual_port_ram_pkg.ram_array;
    constant word_length : natural := 40;
    constant used_radix  : natural := 28;

    use work.real_to_fixed_pkg.all;
    function to_fixed is new generic_to_fixed 
        generic map(word_length => word_length, used_radix => used_radix);

    constant init_values : ram_array(0 to 63)(word_length-1 downto 0) := 
    (
    meas(vac_in)*2           => to_fixed(1.0)
    ,meas(vac_in)*2 + 1      => to_fixed(0.0)
    
    ,meas(vfilter_in)*2      => to_fixed(pri_input_voltage_gain)
    ,meas(vfilter_in)*2 + 1  => to_fixed(pri_input_voltage_offset)
    
    ,meas(vdc_in)*2          => to_fixed(pri_dc_link_gain)
    ,meas(vdc_in)*2 + 1      => to_fixed(pri_dc_link_offset)
    
    ,meas(vdc_out)*2         => to_fixed(pri_dc_link_gain)
    ,meas(vdc_out)*2 + 1     => to_fixed(pri_dc_link_offset)
    
    ,meas(vfilter_out)*2     => to_fixed(pri_input_voltage_gain)
    ,meas(vfilter_out)*2 + 1 => to_fixed(pri_input_voltage_offset)
    
    ,meas(vac_out)*2         => to_fixed(pri_dc_link_gain)
    ,meas(vac_out)*2 + 1     => to_fixed(pri_dc_link_offset)
    
    ,meas(iac_in)*2          => to_fixed(pri_dc_link_gain)
    ,meas(iac_in)*2 + 1      => to_fixed(pri_dc_link_offset)
    
    ,meas(iac_out)*2         => to_fixed(pri_dc_link_gain)
    ,meas(iac_out)*2 + 1     => to_fixed(pri_dc_link_offset)

    ,meas(i_dab)*2           => to_fixed(pri_dc_link_gain)
    ,meas(i_dab)*2 + 1       => to_fixed(pri_dc_link_offset)

    ,others => (others => '0'));

end package meas_pkg;
------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity measurements is
    port (
        main_clock : in std_logic

        ; ad_mux1_io               : out std_logic_vector(2 downto 0)
        ; ads_7056_chip_select_pri : out std_logic
        ; ads_7056_clock_pri       : out std_logic
        ; ads_7056_input_data_pri  : in std_logic

        ; ad_mux2_io           : out std_logic_vector(2 downto 0)
        ; ads_7056_chip_select : out std_logic
        ; ads_7056_clock       : out std_logic
        ; ads_7056_input_data  : in std_logic

        ; bus_from_communications : in fpga_interconnect_record
        ; bus_from_measurements   : out fpga_interconnect_record

        ; adc_scaler_out : out work.adc_scaler_pkg.adc_scaler_out_record(data_out(work.meas_pkg.word_length-1 downto 0))

    );
end entity measurements;

architecture rtl of measurements is

    use work.real_to_fixed_pkg.all;
    use work.ads7056_pkg.all;
    signal pri_ads7056 : ads7056_record := init_ads7056;
    signal sec_ads7056 : ads7056_record := init_ads7056;

    signal pri_mux_pos : natural range 0 to 7 := 0;
    signal sec_mux_pos : natural range 0 to 7 := 0;

    ---- end measurement module signals

    use work.meas_pkg.all;

    use work.adc_scaler_pkg.all;
    signal self_in  : adc_scaler_in_record(data_in(word_length-1 downto 0));
    -- signal self_out : adc_scaler_out_record(data_out(word_length-1 downto 0));

    signal pri_sample_index : natural := 0;
    signal sec_sample_index : natural := 0;
    signal mux1_counter : natural range 0 to 7 := 0;
    signal mux2_counter : natural range 0 to 7 := 0;
    signal ad1_sample_counter : natural := 0;
    signal ad2_sample_counter : natural := 0;

    signal sdm1, sdm2, sdm3, spi1, spi2 : unsigned(15 downto 0) := (others => '0');
    signal sdm1_ready, sdm2_ready, sdm3_ready, spi1_ready, spi2_ready : boolean := false;
    signal sdm1_counter, sdm2_counter, sdm3_counter, spi1_counter, spi2_counter : natural := 0;

    signal ad_counter : natural := 0;

begin

----------------
    measurement_scaling : process(main_clock)
        variable ready : boolean := true;
    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_measurements);

            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 2  , get_converted_measurement(pri_ads7056));
            connect_read_only_data_to_address(bus_from_communications , bus_from_measurements , 3  , get_converted_measurement(sec_ads7056));

            create_ads7056_driver(pri_ads7056         
                                  ,cs            => ads_7056_chip_select_pri 
                                  ,spi_clock_out => ads_7056_clock_pri       
                                  ,serial_io     => ads_7056_input_data_pri);

            create_ads7056_driver(sec_ads7056                   
                                  ,cs            => ads_7056_chip_select    
                                  ,spi_clock_out => ads_7056_clock
                                  ,serial_io     => ads_7056_input_data);

            ad_counter <= ad_counter + 1;
            if ad_counter > 200
            then
                ad_counter <= 0;
            end if;

            if ad_counter = 0 then
                request_conversion(pri_ads7056);
                pri_sample_index <= mux1_counter;
                ad1_sample_counter <= 0;
            end if;

            if ad_counter = 0 then
                request_conversion(sec_ads7056);
                sec_sample_index <= mux2_counter;
                ad2_sample_counter <= 0;
            end if;

            if ad1_sample_counter < 15
            then
                ad1_sample_counter <= ad1_sample_counter + 1;
            end if;

            if ad2_sample_counter < 15
            then
                ad2_sample_counter <= ad2_sample_counter + 1;
            end if;

            if ad1_sample_counter = 14 
            then
                mux1_counter <= mux1_counter + 1;
                if mux1_counter >= 2
                then
                    mux1_counter <= 0;
                end if;
            end if;

            if ad2_sample_counter = 14 
            then
                mux2_counter <= mux2_counter + 1;
                if mux2_counter >= 5
                then
                    mux2_counter <= 3;
                end if;
            end if;

            CASE mux1_counter is
                WHEN 0 => ad_mux1_io <= std_logic_vector(to_unsigned(0,3));
                WHEN 1 => ad_mux1_io <= std_logic_vector(to_unsigned(3,3));
                WHEN 2 => ad_mux1_io <= std_logic_vector(to_unsigned(1,3));
                WHEN others => 
            end CASE;

            CASE mux2_counter is
                WHEN 3 => ad_mux2_io <= std_logic_vector(to_unsigned(0,3));
                WHEN 4 => ad_mux2_io <= std_logic_vector(to_unsigned(2,3));
                WHEN 5 => ad_mux2_io <= std_logic_vector(to_unsigned(1,3));
                WHEN others => 
            end CASE;

            if ad_conversion_is_ready(pri_ads7056) then
                spi1 <= unsigned(get_converted_measurement(pri_ads7056));
                spi1_ready <= true;
            end if;

            if ad_conversion_is_ready(sec_ads7056) then
                spi2 <= unsigned(get_converted_measurement(sec_ads7056));
                spi2_ready <= true;
            end if;

            init_adc_scaler(self_in);
            ready := true;
            scale_measurement(self_in, sdm1_ready , ready , sdm1 , meas(iac_in));
            scale_measurement(self_in, sdm2_ready , ready , sdm2 , meas(iac_out));
            scale_measurement(self_in, sdm3_ready , ready , sdm3 , meas(i_dab));
            scale_measurement(self_in, spi1_ready , ready , spi1 , pri_sample_index);
            scale_measurement(self_in, spi2_ready , ready , spi2 , sec_sample_index);

        end if;
    end process;
----------------
    u_adc_scaler : entity work.adc_scaler
    generic map(init_values, used_radix)
    port map(
        main_clock
        ,self_in
        ,adc_scaler_out
    );
----------------
end rtl;
