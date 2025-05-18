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
    
    use work.dual_port_ram_pkg.all;
    constant dpram_subtype : dpram_ref_record := create_ref_subtypes(datawidth => 16, addresswidth => 10);
    constant ram_init : work.dual_port_ram_pkg.ram_array(0 to dpram_subtype.address_high)(dpram_subtype.data'range) := (others => (others => '0'));

    signal ram_a_in : dpram_subtype.ram_in'subtype;
    signal ram_b_in : dpram_subtype.ram_in'subtype;

    signal ram_a_out : dpram_subtype.ram_out'subtype;
    signal ram_b_out : dpram_subtype.ram_out'subtype;

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

    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;

    use work.microprogram_pkg.all;
    signal mc_read_in       : ref_subtype.ram_read_in'subtype;
    signal mc_read_out      : ref_subtype.ram_read_out'subtype;
    signal mc_write_out     : ref_subtype.ram_write_in'subtype;

    use work.ram_connector_pkg.all;
    signal ram_connector : ram_connector_ref'subtype;

    ----
    signal ext_input        : std_logic_vector(word_length-1 downto 0) := to_fixed(-22.351);
    signal lc_load          : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal lc_duty          : std_logic_vector(word_length-1 downto 0) := to_fixed(0.5);
    signal lc_input_voltage : std_logic_vector(word_length-1 downto 0) := to_fixed(10.0);

    signal simcurrent : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);
    signal simvoltage : std_logic_vector(word_length-1 downto 0) := to_fixed(0.0);

    use work.microprogram_processor_pkg.all;

    signal mproc_in  : microprogram_processor_in_record;
    signal mproc_out : microprogram_processor_out_record;

    signal start_counter : natural range 0 to 127 := 0;

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
         ,clk_out1 => main_clock_120MHz
     );
    -----------------------------

    process(main_clock_120MHz) is
    begin
        if rising_edge(main_clock_120MHz)
        then
            init_bus(bus_from_top);
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 1 , 44252);
            connect_data_to_address(bus_from_communications , bus_from_top , 200 , ext_input(used_radix + 5 downto used_radix+5-15));
            connect_data_to_address(bus_from_communications , bus_from_top , 201 , lc_load(used_radix + 5 downto used_radix+5-15));
            connect_data_to_address(bus_from_communications , bus_from_top , 202 , lc_duty(used_radix + 5 downto used_radix+5-15));
            connect_data_to_address(bus_from_communications , bus_from_top , 203 , lc_input_voltage(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 204 , simcurrent(used_radix + 5 downto used_radix+5-15));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 205 , simvoltage(used_radix + 5 downto used_radix+5-15));

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
    generic map(interconnect_pkg, dpram_subtype)
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
    u_dpram : entity work.dual_port_ram
    generic map(dpram_subtype,ram_init)
    port map(
    main_clock_120MHz
    ,ram_a_in   
    ,ram_a_out  
    --------------
    ,ram_b_in
    ,ram_b_out);

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
