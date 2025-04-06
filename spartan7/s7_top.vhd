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
    
end rtl;
------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.pwm_pkg.all;

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

        ;pfc_pwm1 : out std_logic
        ;pfc_pwm2 : out std_logic

        ;dab_pri_hi  : out std_logic
        ;dab_pri_low : out std_logic
        ;dab_sec_hi  : out std_logic
        ;dab_sec_low : out std_logic

        ;dab_spi_clock : out std_logic
        ;dab_spi_cs    : out std_logic
        ;dab_spi_data  : in std_logic

        ;llc_pri_hi  : out std_logic
        ;llc_pri_low : out std_logic
        ;llc_sec1    : out std_logic
        ;llc_sec2    : out std_logic

        ;llc_spi_clock : out std_logic
        ;llc_spi_cs    : out std_logic
        ;llc_spi_data  : in std_logic

        ;bypass_relay : out std_logic
    );
end entity s7_top;

architecture rtl of s7_top is
    ----------------------------------
    component main_pll
    port
     (-- Clock in ports
      -- Clock out ports
      clk_out1          : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;
    ----------------------------------
    
    package dp_ram_pkg is new work.ram_port_generic_pkg generic map(g_ram_bit_width => 16, g_ram_depth_pow2 => 10);
    use dp_ram_pkg.all;

    signal ram_a_in : ram_in_record;
    signal ram_b_in : ram_in_record;

    signal ram_a_out : ram_out_record;
    signal ram_b_out : ram_out_record;

    package interconnect_pkg is new work.fpga_interconnect_generic_pkg 
        generic map(number_of_data_bits => 16,
                 number_of_address_bits => 16);

    use interconnect_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_measurements   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_top            : fpga_interconnect_record := init_fpga_interconnect;

    signal main_clock_120MHz : std_logic := '0';

    signal led_blink_counter : natural range 0 to 120e6;
    signal led_state : std_logic := '0';


    constant carrier_max : natural := integer(128.0e6/135.0e3);
    signal pwm1 : pwm_record := init_pwm;

begin

    rgb_led1(0) <= led_state;

    dab_pri_hi  <= '0';
    dab_pri_low <= '0';
    dab_sec_hi  <= '0';
    dab_sec_low <= '0';

    llc_pri_hi  <= '0';
    llc_pri_low <= '0';
    llc_sec1    <= '0';
    llc_sec2    <= '0';

    bypass_relay <= '0';
    -----------------------------
    u_main_pll : main_pll
    port map (
         clk_in1    => xclk
         , clk_out1 => main_clock_120MHz
     );
    -----------------------------

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            init_bus(bus_from_top);
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 1 , 44252);

            if led_blink_counter < 60e6 
            then
                led_blink_counter <= led_blink_counter + 1;
            else
                led_blink_counter <= 0;
            end if;


            if led_blink_counter = 0 
            then
                led_state <= not led_state;
            end if;

            init_ram(ram_a_in);
            if data_is_requested_from_address_range(bus_from_communications, 1000, 1007) then
                request_data_from_ram(ram_a_in, get_address(bus_from_communications) - 1000);
            end if;

            if ram_read_is_ready(ram_a_out)
            then
                write_data_to_address(bus_from_top, 0, get_ram_data(ram_a_out));
            end if;

        end if;
    end process;
-------------------------------------------------------
    process(main_clock_120MHz)

    begin
        if rising_edge(main_clock_120MHz)
        then
            pfc_pwm2 <= '0';

            create_pwm(pwm1, pfc_pwm1);
            pfc_pwm1 <= pwm1.pwm;

        end if;
    end process;
-------------------------------------------------------
    u_measurements : entity work.measurements
    generic map(interconnect_pkg, dp_ram_pkg)
    port map(
        main_clock_120MHz
        ,ada_mux   => ada_mux   
        ,ada_clock => ada_clock 
        ,ada_cs    => ada_cs    
        ,ada_data  => ada_data  
        
        ,adb_mux   => adb_mux   
        ,adb_clock => adb_clock 
        ,adb_cs    => adb_cs    
        ,adb_data  => adb_data  



        ,dab_spi_clock => dab_spi_clock 
        ,dab_spi_cs    => dab_spi_cs    
        ,dab_spi_data  => dab_spi_data  
        
        ,llc_spi_clock => llc_spi_clock 
        ,llc_spi_cs    => llc_spi_cs    
        ,llc_spi_data  => llc_spi_data  

        ,bus_to_measurements   => bus_from_communications
        ,bus_from_measurements => bus_from_measurements
        ,ram_b_in  => ram_b_in
    );

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
    create_bus : process(main_clock_120MHz) begin
        if rising_edge(main_clock_120MHz) then
            bus_to_communications <= bus_from_top and bus_from_measurements;
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
