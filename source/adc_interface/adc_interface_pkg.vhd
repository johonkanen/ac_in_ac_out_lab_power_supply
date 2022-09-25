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
    use work.ads7056_pkg.all;
    use work.sigma_delta_cic_filter_pkg.all;
    use work.fpga_interconnect_pkg.all;

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

    alias bus_in is adc_interface_data_in.bus_in;
    alias bus_out is adc_interface_data_out.bus_out;

    signal ads7056     : ads7056_record := init_ads7056(7);
    signal ads7056_pri : ads7056_record := init_ads7056(7);

    signal dab_cic_filter        : cic_filter_record := init_cic_filter;
    signal grid_inu_cic_filter   : cic_filter_record := init_cic_filter;
    signal output_inu_cic_filter : cic_filter_record := init_cic_filter;
    signal sdm_clock_counter : integer range 0 to 2**4-1 := 0;
    signal sdm_io_clock : std_logic := '0';
    signal dab_io_data        : std_logic := '0';
    signal output_sdm_io_data : std_logic := '0';
    signal grid_sdm_io_data   : std_logic := '0';
    signal pll_lock_pipeline : std_logic_vector(7 downto 0) := (others => '0');

    signal initial_delay : integer range 0 to 2**20-1 := 500e3;

    function to_std_logic_vector
    (
        data : integer
    )
    return std_logic_vector 
    is
    begin
        return std_logic_vector(to_unsigned(data, 3));
    end to_std_logic_vector;

begin
    -- ad mux1 positions 0: afe voltage, 1: output voltage, 2: dc link
    adc_interface_FPGA_out <= (ad_mux_channel_select1 => to_std_logic_vector(0)               ,
                                chip_select1          =>  ads7056.chip_select_out             ,
                                spi_clock1            =>  ads7056.clock_divider.divided_clock ,

    -- ad mux2 positions 1: dc link, 2: afe_voltage, 3: grid voltage
                                ad_mux_channel_select2 => to_std_logic_vector(2)                  ,
                                chip_select2           => ads7056_pri.chip_select_out             ,
                                spi_clock2             => ads7056_pri.clock_divider.divided_clock ,

                                dab_sdm_clock        =>  sdm_io_clock,
                                grid_inu_sdm_clock   =>  sdm_io_clock,
                                output_inu_sdm_clock =>  sdm_io_clock);

------------------------------------------------------------------------

    test_adc : process(clock)
    begin
        if rising_edge(clock) then
            create_ads7056(ads7056, adc_interface_FPGA_in.spi_data1);
            create_ads7056(ads7056_pri, adc_interface_FPGA_in.spi_data2);
            init_bus(bus_out);
            connect_read_only_data_to_address(bus_in , bus_out , 5000 , get_cic_filter_output(dab_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5001 , get_cic_filter_output(output_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5002 , get_cic_filter_output(grid_inu_cic_filter));
            connect_read_only_data_to_address(bus_in , bus_out , 5003 , get_ad_measurement(ads7056));
            connect_read_only_data_to_address(bus_in , bus_out , 5004 , get_ad_measurement(ads7056_pri));
            connect_read_only_data_to_address(bus_in , bus_out , 5005 , 33585);

            pll_lock_pipeline <= pll_lock_pipeline(6 downto 0) & pll_locked;

            if initial_delay > 0 then
                initial_delay <= initial_delay - 1;
            end if;

            if pll_lock_pipeline = x"ff" and initial_delay = 5000 then
                initialize_ads7056(ads7056);
                initialize_ads7056(ads7056_pri);
            end if;

            if initial_delay = 0 then
                initial_delay <= 1199;
                request_ad_conversion(ads7056);
                request_ad_conversion(ads7056_pri);
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
