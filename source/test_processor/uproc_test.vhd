library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fpga_interconnect_pkg.all;

entity uproc_test is
    generic ( g_word_length : natural := 32
              ;g_used_radix : natural := 24

            );
    port ( 
        clock : in std_logic 
        ; bus_from_communications : in fpga_interconnect_record
        ; bus_from_uproc          : out fpga_interconnect_record
        ; measurement             : in std_logic_vector(31 downto 0) := (others => '0')
    );
end entity uproc_test;

