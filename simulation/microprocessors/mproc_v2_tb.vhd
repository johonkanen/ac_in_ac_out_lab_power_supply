LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity mrpoc_v2_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of mrpoc_v2_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 120000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    constant instruction_length : natural := 32;
    constant word_length        : natural := 40;
    constant used_radix         : natural := 20;

    --
    use work.microprogram_processor_pkg.all;
    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;
    use work.fpga_interconnect_pkg.all;

    signal bus_from_communications : fpga_interconnect_record := init_fpga_interconnect;
    signal bus_from_uproc2 : fpga_interconnect_record := init_fpga_interconnect;


    signal simcurrent : real := 0.0;
    signal simvoltage : real := 0.0;
    signal dingdong : real := 0.0;
    signal slv_current : std_logic_vector(31 downto 0) := (others => '0');

    use ieee.float_pkg.all;
    signal request_counter : natural := 0;
    signal capture_counter : natural := 0;

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

        -- function convert(data_in : std_logic_vector) return real is
        -- begin
        --     return to_real(to_hfloat(data_in, hfloat_ref));
        -- end convert;
        --
        -- use work.ram_connector_pkg.generic_connect_ram_write_to_address;
        -- procedure connect_ram_write_to_address is new generic_connect_ram_write_to_address generic map(return_type => real, conv => convert);


    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            init_bus(bus_from_communications);


            CASE simulation_counter is
                WHEN 13  => write_data_to_address(bus_from_communications , 1011 , to_slv(to_float(1.0)));
                WHEN 14  => write_data_to_address(bus_from_communications , 1012 , to_slv(to_float(-2.0)));
                WHEN 15  => write_data_to_address(bus_from_communications , 1013 , to_slv(to_float(3.0)));
                WHEN 99  => write_data_to_address(bus_from_communications , 599 , x"0000_0001");
                                    request_counter <= 0;
                                    capture_counter <= 0;
                WHEN 100  => write_data_to_address(bus_from_communications,1024, to_slv(to_float(0.6)));
                                    request_counter <= 0;
                                    capture_counter <= 0;
                WHEN 200  => write_data_to_address(bus_from_communications,1122, to_slv(to_float(0.8)));
                                    request_counter <= 0;
                                    capture_counter <= 0;
                WHEN 41e3 => write_data_to_address(bus_from_communications,1122, to_slv(to_float(0.7)));
                                    request_counter <= 0;
                                    capture_counter <= 0;
                WHEN 50e3 => write_data_to_address(bus_from_communications,1121, to_slv(to_float(4.0)));
                                    request_counter <= 0;
                                    capture_counter <= 0;
                WHEN others => -- do nothing
                    if simulation_counter > 50
                    then

                        if request_counter < 5 then
                            request_counter <= request_counter + 1;
                        end if;

                        CASE request_counter is
                            WHEN 0 => request_data_from_address(bus_from_communications ,600);
                                    capture_counter <= 0;
                            WHEN 1 => request_data_from_address(bus_from_communications ,601);
                            WHEN 2 => request_data_from_address(bus_from_communications ,602);
                            WHEN others => -- do nothing
                        end CASE;

                        if write_is_requested_to_address(bus_from_uproc2, 0)
                        then
                            capture_counter <= capture_counter + 1;
                            CASE capture_counter is
                                WHEN 0 => simcurrent <= to_real(to_float(get_slv_data(bus_from_uproc2)));
                                WHEN 1 => simvoltage <= to_real(to_float(get_slv_data(bus_from_uproc2)));
                                WHEN 2 => dingdong   <= to_real(to_float(get_slv_data(bus_from_uproc2)));
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
u_uproc2_test : entity work.uproc_test(v2)
generic map(g_word_length => word_length
           )
port map( 
    clock => simulator_clock
    ,bus_from_communications => bus_from_communications
    ,bus_from_uproc          => bus_from_uproc2);
------------------------------------------------------------------------

end vunit_simulation;
