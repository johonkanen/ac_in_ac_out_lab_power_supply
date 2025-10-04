LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity mrpoc_v3_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of mrpoc_v3_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 120000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    constant instruction_length : natural := 32;
    constant word_length        : natural := 32;
    constant used_radix         : natural := 20;

    --
    use work.microprogram_processor_pkg.all;
    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;
    use work.fpga_interconnect_pkg.all;

    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_uproc3 : fpga_interconnect_record := init_fpga_interconnect;


    signal simcurrent : real := 0.0;
    signal simvoltage : real := 0.0;
    signal dingdong : real := 0.0;
    signal dingdong2 : real := 0.0;
    signal slv_current : std_logic_vector(31 downto 0) := (others => '0');

    use ieee.float_pkg.all;
    signal request_counter : natural := 0;
    signal capture_counter : natural := 0;

    constant g_used_radix : natural := 28;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)

        use work.real_to_fixed_pkg;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            init_bus(bus_from_communications);


            CASE simulation_counter is
                WHEN 13  => write_data_to_address(bus_from_communications , 1011 , to_slv(to_float(1.0)));
                WHEN 14  => write_data_to_address(bus_from_communications , 1012 , to_slv(to_float(2.0)));
                WHEN 15  => write_data_to_address(bus_from_communications , 1013 , to_slv(to_float(4.0)));
                WHEN 16  => write_data_to_address(bus_from_communications , 398 , std_logic_vector(to_unsigned(100,32)));
                WHEN 99  => write_data_to_address(bus_from_communications , 399 , x"0000_0001");
                WHEN others => -- do nothing
                    if simulation_counter > 50
                    then

                        if request_counter < 10 then
                            request_counter <= request_counter + 1;
                        end if;

                        CASE request_counter is
                            WHEN 0 => request_data_from_address(bus_from_communications ,500);
                                    capture_counter <= 0;
                            WHEN 1 => request_data_from_address(bus_from_communications ,501);
                            WHEN 2 => request_data_from_address(bus_from_communications ,502);
                            WHEN 3 => request_data_from_address(bus_from_communications ,503);
                            WHEN others => -- do nothing
                        end CASE;

                        if write_is_requested_to_address(bus_from_uproc3, 0)
                        then
                            capture_counter <= capture_counter + 1;
                            CASE capture_counter is
                                WHEN 0 => simcurrent <= real_to_fixed_pkg.to_real(get_slv_data(bus_from_uproc3),g_used_radix);
                                WHEN 1 => simvoltage <= real_to_fixed_pkg.to_real(get_slv_data(bus_from_uproc3),g_used_radix);
                                WHEN 2 => dingdong   <= real_to_fixed_pkg.to_real(get_slv_data(bus_from_uproc3),g_used_radix);
                                WHEN 3 => dingdong2  <= real_to_fixed_pkg.to_real(get_slv_data(bus_from_uproc3),g_used_radix);
                                    request_counter <= 0;
                                WHEN others => -- do nothing
                            end CASE;
                        end if;

                    end if;
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
------------------------------------------------------------------------
u_uproc3_test : entity work.uproc_test(v3)
generic map(g_word_length => word_length
            ,g_used_radix => g_used_radix
           )
port map( 
    clock => simulator_clock
    ,bus_from_communications => bus_from_communications
    ,bus_from_uproc          => bus_from_uproc3);
------------------------------------------------------------------------

end vunit_simulation;
