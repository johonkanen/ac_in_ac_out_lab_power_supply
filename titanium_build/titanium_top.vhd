---------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity titanium_top is
    port (
        main_clock : in std_logic;
        pll_locked   : in std_logic;

        uart_rx      : in std_logic;
        uart_tx      : out std_logic;

        grid_inu_leg1_hi  : out std_logic;
        grid_inu_leg1_low : out std_logic;
        grid_inu_leg2_hi  : out std_logic;
        grid_inu_leg2_low : out std_logic;

        dab_primary_hi    : out std_logic;
        dab_primary_low   : out std_logic;
        dab_secondary_hi  : out std_logic;
        dab_secondary_low : out std_logic;

        output_inu_leg1_hi  : out std_logic;
        output_inu_leg1_low : out std_logic;
        output_inu_leg2_hi  : out std_logic;
        output_inu_leg2_low : out std_logic;

        primary_bypass_relay   : out std_logic;
        secondary_bypass_relay : out std_logic;

        gate_power1_pwm : out std_logic;
        gate_power2_pwm : out std_logic;
        gate_power3_pwm : out std_logic;
        gate_power4_pwm : out std_logic;
        gate_power5_pwm : out std_logic;
        gate_power6_pwm : out std_logic;

        grid_inu_sdm_clock   : out std_logic;
        output_inu_sdm_clock : out std_logic;
        dab_sdm_clock        : out std_logic;

        ad_mux1_io           : out std_logic_vector(2 downto 0);
        ads_7056_clock       : out std_logic;
        ads_7056_chip_select : out std_logic;
        ads_7056_input_data  : in std_logic;

        ad_mux2_io               : out std_logic_vector(2 downto 0);
        ads_7056_clock_pri       : out std_logic;
        ads_7056_chip_select_pri : out std_logic;
        ads_7056_input_data_pri  : in std_logic;

        grid_inu_sdm_data   : in std_logic;
        output_inu_sdm_data : in std_logic;
        dab_sdm_data        : in std_logic

        -- leds         : out std_logic_vector(3 downto 0)
    );
end entity titanium_top;

architecture rtl of titanium_top is

    use work.fpga_interconnect_pkg.all;
    use work.ads7056_pkg.all;
    use work.aux_pwm_pkg.all;
    use work.git_hash_pkg;
    use work.sigma_delta_cic_filter_pkg.all;
    use work.pwm_pkg.all;
    use work.real_to_fixed_pkg.all;

    signal bus_to_communications   : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_top          : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_uproc        : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_signal_scope : fpga_interconnect_record := init_fpga_interconnect;

    signal bus_from_measurements : fpga_interconnect_record := init_fpga_interconnect;

    signal trigger_event : boolean;
    signal sampled_data : std_logic_vector(15 downto 0);

    signal test_data  : std_logic_vector(31 downto 0) :=x"0000acdc";
    signal test_data2 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal test_data3 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal test_data4 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    signal aux_pwm : aux_pwm_record := init_aux_period_and_duty(period => 500, duty_cycle => 220);

    signal grid_inu_filter : cic_filter_record := init_cic_filter;
    signal output_inu_filter : cic_filter_record := init_cic_filter;
    signal dab_filter : cic_filter_record := init_cic_filter;
    signal sdm_counter : natural range 0 to 15 := 0;

    signal pwm : pwm_record := init_pwm;
    signal test_counter : natural range 0 to 2**16-1 := 0;
    
    package mpy_pkg is new work.multiplier_generic_pkg generic map(24,1,1);
        use mpy_pkg.all;

    package div_pkg is new work.division_generic_pkg generic map(mpy_pkg, g_max_shift => 8);
        use div_pkg.all;

    signal div_mpy : multiplier_record := init_multiplier;
    signal divider : division_record   := init_division;

    signal conversion_requested : boolean := false;

    use work.main_state_machine_pkg.all;
    signal main_state_machine : main_state_record := init_main_state;

    signal precharge_delay_counter : natural range 0 to 65535 := 65535;
    signal adc_scaler_out : work.adc_scaler_pkg.adc_scaler_out_record(data_out(work.meas_pkg.word_length-1 downto 0));

    use work.dual_port_ram_pkg.all;
    constant meas_ram_subtype : dpram_ref_record := 
        create_ref_subtypes(
            datawidth      => work.meas_pkg.word_length
            , addresswidth => 4);

    --------------------
    signal meas_ram_a_in  : meas_ram_subtype.ram_in'subtype;
    signal meas_ram_a_out : meas_ram_subtype.ram_out'subtype;
    --------------------
    signal meas_ram_b_in  : meas_ram_a_in'subtype;
    signal meas_ram_b_out : meas_ram_a_out'subtype;
    --------------------
    use ieee.float_pkg.all;
    signal fp32_mult_a  : std_logic_vector(31 downto 0) :=to_slv(to_float(-1.0, float32'high)); -- fp32_mult_a
    signal fp32_mult_b  : std_logic_vector(31 downto 0) :=to_slv(to_float(1.0, float32'high)); -- fp32_mult_b
    signal fp32_adder_a : std_logic_vector(31 downto 0) :=to_slv(to_float(-3.5, float32'high)); -- fp32_chainin
    signal ena          : std_logic_vector(2 downto 0)  := (others => '1'); -- ena
    signal fp32_result  : std_logic_vector(31 downto 0)                   ; -- fp32_result

    type fp32_in_record is record
        fp32_mult_a  : std_logic_vector(31 downto 0);
        fp32_mult_b  : std_logic_vector(31 downto 0);
        fp32_adder_a : std_logic_vector(31 downto 0);
    end record;

    -- procedure fmult(signal fp32_in : out fp32_in_record; mul_a : std_logic_vector; mul_b : std_logic_vector; add_a : std_logic_vector) is
    -- begin
    --     fp32_in <=(mul_a, mul_b, (others => '0');
    -- end fmult;


    -- agilex 3 only, left as blackbox in efinix titanium
    -----------------------------------------------------
	component native_fp32 is
		port (
			fp32_mult_a  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_mult_a
			fp32_mult_b  : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_mult_b
			fp32_adder_a : in  std_logic_vector(31 downto 0) := (others => 'X'); -- fp32_adder_a
			clk          : in  std_logic                     := 'X';             -- clk
			ena          : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- ena
			fp32_result  : out std_logic_vector(31 downto 0)                     -- fp32_result
		);
	end component native_fp32;
    -----------------------------------------------------
        
begin

    --------------------
	u0 : component native_fp32
		port map (
            fp32_mult_a   => fp32_mult_a  -- fp32_mult_a.fp32_mult_a
            ,fp32_mult_b  => fp32_mult_b  -- fp32_mult_b.fp32_mult_b
            ,fp32_adder_a => fp32_adder_a -- fp32_mult_b.fp32_mult_b
            ,clk          => main_clock   -- clk.clk
            ,ena          => "111"        -- ena.ena
            ,fp32_result  => fp32_result  -- fp32_result.fp32_result
		);

	-- u1 : component native_fp32
	-- 	port map (
	--            fp32_mult_a   => fp32_mult_a  -- fp32_mult_a.fp32_mult_a
	--            ,fp32_mult_b  => fp32_mult_b  -- fp32_mult_b.fp32_mult_b
	--            ,fp32_adder_a => fp32_adder_a -- fp32_mult_b.fp32_mult_b
	--            ,clk          => main_clock   -- clk.clk
	--            ,ena          => "111"        -- ena.ena
	--            ,fp32_result  => fp32_result  -- fp32_result.fp32_result
	-- 	);
    --------------------

    grid_inu_leg1_hi  <= '0';
    grid_inu_leg1_low <= '0';
    grid_inu_leg2_hi  <= '0';
    -- grid_inu_leg2_low <= '0';

    dab_primary_hi    <= '0';
    dab_primary_low   <= '0';
    dab_secondary_hi  <= '0';
    dab_secondary_low <= '0';

    output_inu_leg1_hi  <= '0';
    output_inu_leg1_low <= '0';
    output_inu_leg2_hi  <= '0';
    output_inu_leg2_low <= '0';

    primary_bypass_relay   <= '0';
    secondary_bypass_relay <= '0';

------------------------------------------------------------------------
    process(main_clock) is

        ----------------------
        impure function start_requested return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 1;
        end start_requested;

        ----------------------
        impure function shutdown_requested return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 0;
        end shutdown_requested;

        ----------------------
        impure function acknowledge_fault return boolean is
        begin
            return write_is_requested_to_address(bus_from_communications, 10) 
                and get_data(bus_from_communications) = 2;
        end acknowledge_fault;
        ----------------------
        procedure start_precharge is
        begin
            if precharge_delay_counter < integer(50.0e-3 * 120.0e6)
            then
                precharge_delay_counter <= precharge_delay_counter + 1;
            end if;

            if start_requested
            then
                precharge_delay_counter <= 0;
            end if;

        end start_precharge;
        ----------------------
        ----------------------
        procedure create_main_state_machine is new generic_main_state_machine 
            generic map(start_precharge);
        ----------------------

    begin
        if rising_edge(main_clock) then
            init_bus(bus_from_top);

            create_main_state_machine(main_state_machine
                 , start_requested    => start_requested
                 , precharge_ready    => precharge_delay_counter = integer(50.0e-3 * 120.0e6)
                 , fault_detected     => false
                 , fault_acknowledged => acknowledge_fault
                 , shutdown_requested => shutdown_requested
            );

            create_pwm(pwm,grid_inu_leg2_low);
            
            connect_data_to_address(bus_from_communications , bus_from_top , 1 , test_data);
            connect_data_to_address(bus_from_communications , bus_from_top , 4 , test_data2);

            connect_data_to_address(bus_from_communications , bus_from_top , 50 , fp32_mult_a );
            connect_data_to_address(bus_from_communications , bus_from_top , 51 , fp32_mult_b );
            connect_data_to_address(bus_from_communications , bus_from_top , 52 , fp32_adder_a);
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 53 , fp32_result);


            if write_is_requested_to_address(bus_from_communications, 10) and get_data(bus_from_communications) = 1 then
                pwm.is_enabled <= true;
            end if;
            if write_is_requested_to_address(bus_from_communications, 10) and (get_data(bus_from_communications) /= 1) then
                pwm.is_enabled <= false;
            end if;

            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 6 , 2**15 + get_cic_filter_output(grid_inu_filter));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 7 , 2**15 + get_cic_filter_output(output_inu_filter));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 8 , 2**15 + get_cic_filter_output(dab_filter));
            connect_read_only_data_to_address(bus_from_communications , bus_from_top , 12 , report_state(main_state_machine));

            -- connect_read_only_data_to_address(bus_from_communications , bus_from_top , 100 , git_hash_pkg.git_hash);

            init_ram(meas_ram_b_in);
            if data_is_requested_from_address_range(bus_from_communications, 200, 209)
            then
                request_data_from_ram(meas_ram_b_in, get_address(bus_from_communications) - 200);
            end if;
            if ram_read_is_ready(meas_ram_b_out) then
                write_data_to_address(bus_from_top, 0, get_ram_data(meas_ram_b_out)(39-15 to 39));
            end if;

            create_aux_pwm(aux_pwm);
            if test_data2(0) then
                start_aux_pwm(aux_pwm);
            end if;
            gate_power1_pwm <= aux_pwm.pwm_out and test_data2(1);
            gate_power2_pwm <= aux_pwm.pwm_out and test_data2(2);
            gate_power3_pwm <= aux_pwm.pwm_out and test_data2(3);
            gate_power4_pwm <= aux_pwm.pwm_out and test_data2(4);
            gate_power5_pwm <= aux_pwm.pwm_out and test_data2(5);
            gate_power6_pwm <= aux_pwm.pwm_out and test_data2(6);

            if sdm_counter < 5 then
                sdm_counter <= sdm_counter + 1;
            else
                sdm_counter <= 0;
                calculate_cic_filter(grid_inu_filter   , grid_inu_sdm_data);
                calculate_cic_filter(output_inu_filter , output_inu_sdm_data);
                calculate_cic_filter(dab_filter        , dab_sdm_data);
            end if;

            if sdm_counter > 5/2 then
                grid_inu_sdm_clock   <= '0';
                output_inu_sdm_clock <= '0';
                dab_sdm_clock        <= '0';
            else
                grid_inu_sdm_clock   <= '1';
                output_inu_sdm_clock <= '1';
                dab_sdm_clock        <= '1';
            end if;

            if test_counter < 4000 then
                test_counter <= test_counter + 1;
            else
                test_counter <= 0;
            end if;

        end if;
    end process;

------------------------------------------------------------------------
    u_meas_ram : entity work.dual_port_ram
    generic map(meas_ram_subtype)
    port map(
    main_clock
    , meas_ram_a_in   
    , meas_ram_a_out  
    --------------
    , meas_ram_b_in  
    , meas_ram_b_out);

    -- TODO, make a subroutine for this
    meas_ram_a_in <=(address => to_unsigned(adc_scaler_out.out_address,4)
                    ,read_is_requested => '0'
                    ,data => std_logic_vector(adc_scaler_out.data_out)
                    ,write_requested => adc_scaler_out.is_ready);

------------------------------------------------------------------------
    u_measurements : entity work.measurements
    port map (
        main_clock => main_clock

        , ad_mux1_io => ad_mux1_io
        , ads_7056_chip_select_pri => ads_7056_chip_select_pri
        , ads_7056_clock_pri       => ads_7056_clock_pri
        , ads_7056_input_data_pri  => ads_7056_input_data_pri

        , ad_mux2_io => ad_mux2_io
        , ads_7056_chip_select => ads_7056_chip_select
        , ads_7056_clock       => ads_7056_clock
        , ads_7056_input_data  => ads_7056_input_data

        , bus_from_communications => bus_from_communications
        , bus_from_measurements   => bus_from_measurements

        , adc_scaler_out => adc_scaler_out

    );
------------------------------------------------------------------------
    u_signal_scope : entity work.signal_scope
        generic map( 16, 8)
        port map(
            main_clock
            ,bus_from_communications
            ,bus_from_signal_scope
            ,trigger_event
            ,true
            ,sampled_data
        );

    sampled_data <= std_logic_vector(to_unsigned(test_counter, 16));
    trigger_event <= test_counter = 3e3;

------------------------------------------------------------------------
    combine_buses : process(main_clock) is
    begin
        if rising_edge(main_clock)
        then
            bus_to_communications <= bus_from_top 
                                     and bus_from_signal_scope 
                                     and bus_from_measurements 
                                     and bus_from_uproc 
                                     ;
        end if; -- rising_edge
    end process;

------------------------------------------------------------------------
    u_fpga_communications : entity work.fpga_communications
    generic map(fpga_interconnect_pkg => work.fpga_interconnect_pkg, g_clock_divider => 24)
        port map(
            clock                    => main_clock
            ,uart_rx                 => uart_rx
            ,uart_tx                 => uart_tx
            ,bus_to_communications   => bus_to_communications
            ,bus_from_communications => bus_from_communications
        );
        
------------------------------------------------------------------------
u_uproc_test : entity work.uproc_test
port map( 
    clock => main_clock
    ,bus_from_communications => bus_from_communications
    ,bus_from_uproc          => bus_from_uproc);
------------------------------------------------------------------------

end rtl;
