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
