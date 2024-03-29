library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

package adc_interface_pkg is

    type adc_interface_FPGA_input_group is record
        dab_sdm_data    : std_logic;
        grid_sdm_data   : std_logic;
        output_sdm_data : std_logic;
        spi_data1       : std_logic;
        spi_data2       : std_logic;

    end record;
    
    type adc_interface_FPGA_output_group is record
        dab_sdm_clock        : std_logic;
        grid_inu_sdm_clock   : std_logic;
        output_inu_sdm_clock : std_logic;

        spi_clock1   : std_logic;
        chip_select1 : std_logic;

        spi_clock2   : std_logic;
        chip_select2 : std_logic;

        ad_mux_channel_select1 : std_logic_vector(2 downto 0);
        ad_mux_channel_select2 : std_logic_vector(2 downto 0);
    end record;
    
    type adc_interface_data_input_group is record
        bus_in : fpga_interconnect_record;
    end record;
    
    type adc_interface_data_output_group is record
        bus_out : fpga_interconnect_record;
    end record;
    
end package adc_interface_pkg;

package body adc_interface_pkg is

end package body adc_interface_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.adc_interface_pkg.all;
    use work.sigma_delta_cic_filter_pkg.all;
    use work.fpga_interconnect_pkg.all;
    use work.muxed_adc_pkg.all;

entity adc_interface is
    port (
        clock : in std_logic;
        pll_locked : in std_logic;
        adc_interface_FPGA_in  : in adc_interface_FPGA_input_group;
        adc_interface_FPGA_out : out adc_interface_FPGA_output_group;
        adc_interface_data_in  : in adc_interface_data_input_group;
        adc_interface_data_out : out adc_interface_data_output_group
    );
end entity adc_interface;

architecture rtl of adc_interface is

    alias bus_in  is adc_interface_data_in.bus_in;
    alias bus_out is adc_interface_data_out.bus_out;

    signal muxed_adc     : muxed_adc_record := init_muxed_adc(5);
    signal muxed_adc_pri : muxed_adc_record := init_muxed_adc(5);

    signal dab_cic_filter        : cic_filter_record            := init_cic_filter;
    signal grid_inu_cic_filter   : cic_filter_record            := init_cic_filter;
    signal output_inu_cic_filter : cic_filter_record            := init_cic_filter;
    signal sdm_clock_counter     : integer range 0 to 2**4-1    := 0;
    signal sdm_io_clock          : std_logic                    := '0';
    signal dab_io_data           : std_logic                    := '0';
    signal output_sdm_io_data    : std_logic                    := '0';
    signal grid_sdm_io_data      : std_logic                    := '0';
    signal pll_lock_pipeline     : std_logic_vector(7 downto 0) := (others => '0');
    signal initial_delay         : integer range 0 to 2**20-1   := 500e3;
    signal channel               : integer range 0 to 7         := 0;

    signal measurements     : measurements_array := (others => 0);
    signal pri_measurements : measurements_array := (others => 0);

------------------------------------------------------------------------
begin
    -- ad mux1 positions 0: afe voltage, 1: output voltage, 2: dc link
    adc_interface_FPGA_out <= (ad_mux_channel_select1 => get_ad_mux_io(muxed_adc)                       ,
                                chip_select1          =>  muxed_adc.ads7056.chip_select_out             ,
                                spi_clock1            =>  muxed_adc.ads7056.clock_divider.divided_clock ,

    -- ad mux2 positions 1: dc link, 2: afe_voltage, 3: grid voltage
                                ad_mux_channel_select2 => get_ad_mux_io(muxed_adc_pri)                      ,
                                chip_select2           => muxed_adc_pri.ads7056.chip_select_out             ,
                                spi_clock2             => muxed_adc_pri.ads7056.clock_divider.divided_clock ,

                                dab_sdm_clock        =>  sdm_io_clock,
                                grid_inu_sdm_clock   =>  sdm_io_clock,
                                output_inu_sdm_clock =>  sdm_io_clock);

------------------------------------------------------------------------

    test_adc : process(clock)
    begin
        if rising_edge(clock) then
            create_muxed_adc(muxed_adc     , adc_interface_FPGA_in.spi_data1);
            create_muxed_adc(muxed_adc_pri , adc_interface_FPGA_in.spi_data2);

            init_bus(bus_out);
            connect_read_only_data_to_address(bus_in , bus_out , 5000 , get_cic_filter_output(dab_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5001 , get_cic_filter_output(output_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5002 , get_cic_filter_output(grid_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5003 , get_ad_measurement(muxed_adc));
            connect_read_only_data_to_address(bus_in , bus_out , 5004 , get_ad_measurement(muxed_adc_pri));
            connect_read_only_data_to_address(bus_in , bus_out , 5005 , measurements(0));
            connect_read_only_data_to_address(bus_in , bus_out , 5006 , measurements(1));
            connect_read_only_data_to_address(bus_in , bus_out , 5007 , measurements(2));
            connect_read_only_data_to_address(bus_in , bus_out , 5008 , measurements(3));
            connect_read_only_data_to_address(bus_in , bus_out , 5009 , measurements(4));
            connect_read_only_data_to_address(bus_in , bus_out , 5010 , measurements(5));
            connect_read_only_data_to_address(bus_in , bus_out , 5011 , measurements(6));
            connect_read_only_data_to_address(bus_in , bus_out , 5012 , measurements(7));
            connect_read_only_data_to_address(bus_in , bus_out , 5013 , pri_measurements(0));
            connect_read_only_data_to_address(bus_in , bus_out , 5014 , pri_measurements(1));
            connect_read_only_data_to_address(bus_in , bus_out , 5015 , pri_measurements(2));
            connect_read_only_data_to_address(bus_in , bus_out , 5016 , pri_measurements(3));
            connect_read_only_data_to_address(bus_in , bus_out , 5017 , pri_measurements(4));
            connect_read_only_data_to_address(bus_in , bus_out , 5018 , pri_measurements(5));
            connect_read_only_data_to_address(bus_in , bus_out , 5019 , pri_measurements(6));
            connect_read_only_data_to_address(bus_in , bus_out , 5020 , pri_measurements(7));

            pll_lock_pipeline <= pll_lock_pipeline(6 downto 0) & pll_locked;

            if initial_delay > 0 then
                initial_delay <= initial_delay - 1;
            end if;

            if pll_lock_pipeline = x"ff" and initial_delay = 5000 then
                init_adc(muxed_adc);
                init_adc(muxed_adc_pri);
            end if;

            if initial_delay = 0 then
                initial_delay <= 149;
                request_ad_conversion(muxed_adc);
                request_ad_conversion(muxed_adc_pri);
                channel <= channel + 1;
                setup_next_channel(muxed_adc     , channel + 1);
                setup_next_channel(muxed_adc_pri , channel + 1);
            end if;

            if ad_measurement_is_ready(muxed_adc) then
                measurements(get_triggered_adc_channel(muxed_adc)) <= get_ad_measurement(muxed_adc);
            end if;

            if ad_measurement_is_ready(muxed_adc_pri) then
                pri_measurements(get_triggered_adc_channel(muxed_adc_pri)) <= get_ad_measurement(muxed_adc_pri);
            end if;


            if sdm_clock_counter > 0 then
                sdm_clock_counter <= sdm_clock_counter - 1;
            else
                sdm_clock_counter <= 5;
            end if;

            if sdm_clock_counter > 2 then
                sdm_io_clock <= '1';
            else
                sdm_io_clock <= '0';
            end if;

            if sdm_clock_counter = 3 then
                dab_io_data        <= adc_interface_FPGA_in.dab_sdm_data   ;
                grid_sdm_io_data   <= adc_interface_FPGA_in.grid_sdm_data  ;
                output_sdm_io_data <= adc_interface_FPGA_in.output_sdm_data  ;

                calculate_cic_filter(dab_cic_filter        , dab_io_data);
                calculate_cic_filter(grid_inu_cic_filter   , grid_sdm_io_data);
                calculate_cic_filter(output_inu_cic_filter , output_sdm_io_data);
            end if;

        end if; --rising_edge
    end process test_adc;	
------------------------------------------------------------------------
end rtl;
