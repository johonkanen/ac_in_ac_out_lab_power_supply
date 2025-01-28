
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity signal_scope is
    generic(g_ram_bit_width : positive
            ;g_ram_depth_pow2 : positive
           );
    port (
      main_clock              : in std_logic
      ; bus_in                : in work.fpga_interconnect_pkg.fpga_interconnect_record
      ; bus_from_signal_scope : out work.fpga_interconnect_pkg.fpga_interconnect_record
      ; sample_event          : in boolean
      ; sampled_data          : in std_logic_vector
    );
end entity signal_scope;

architecture rtl of signal_scope is

    use work.fpga_interconnect_pkg.all;
    package scope_ram_port_pkg is new work.ram_port_generic_pkg 
        generic map(
            g_ram_bit_width => 16
            , g_ram_depth_pow2 => 12);

    package scope_sample_trigger_pkg is new work.sample_trigger_generic_pkg 
        generic map(g_ram_depth => scope_ram_port_pkg.ram_depth);

    use scope_ram_port_pkg.all;
    use scope_sample_trigger_pkg.all;

    procedure create_scope(
      signal trigger          : inout sample_trigger_record
      ; bus_in                : in fpga_interconnect_record
      ; signal bus_out        : out fpga_interconnect_record
      ; signal ram_port_in_b  : out ram_in_record
      ; signal ram_port_out_b : in ram_out_record
      ; sample_event          : in boolean
      ; sampled_data          : in std_logic_vector

    ) is
    begin
        create_trigger(trigger, sample_event);

        if sampling_enabled(trigger) then
            write_data_to_ram(ram_port_in_b, get_sample_address(trigger), sampled_data);
        else
            if data_is_requested_from_address(bus_in, 1001) then
                calculate_read_address(trigger);
                request_data_from_ram(ram_port_in_b, get_sample_address(trigger));
            end if;
        end if;

        if data_is_requested_from_address(bus_in, 1000) then
            write_data_to_address(bus_out, address => 0, data => 1);
            prime_trigger(trigger, ram_depth/2);
        end if;

        if ram_read_is_ready(ram_port_out_b) then
            write_data_to_address(bus_out, address => 0, data => get_ram_data(ram_port_out_b));
        end if;
    end create_scope;

    signal sample_trigger : sample_trigger_record := init_trigger;

    signal ram_a_in  : ram_in_record;
    signal ram_a_out : ram_out_record;
    --------------------
    signal ram_b_in  : ram_in_record;
    signal ram_b_out : ram_out_record;

begin

    process(main_clock) is
    begin
        if rising_edge(main_clock) then
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            init_bus(bus_from_signal_scope);

            create_scope(sample_trigger
            , bus_in
            , bus_from_signal_scope
            , ram_b_in
            , ram_b_out
            , sample_event
            , sampled_data
            );
        end if;
    end process;

    u_dpram : entity work.generic_dual_port_ram
    generic map(scope_ram_port_pkg)
    port map(
    main_clock ,
    ram_a_in   ,
    ram_a_out  ,
    --------------
    ram_b_in  ,
    ram_b_out);
------------------------------------------------------------------------

end rtl;

------------------------------------------------
