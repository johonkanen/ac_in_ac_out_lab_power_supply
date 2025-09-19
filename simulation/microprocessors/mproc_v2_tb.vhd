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
    constant simtime_in_clocks : integer := 20000;
    
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
        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
------------------------------------------------------------------------
u_uproc2_test : entity work.uproc_test(v2)
port map( 
    clock => simulator_clock
    ,bus_from_communications => bus_from_communications
    ,bus_from_uproc          => bus_from_uproc2);
------------------------------------------------------------------------

end vunit_simulation;
