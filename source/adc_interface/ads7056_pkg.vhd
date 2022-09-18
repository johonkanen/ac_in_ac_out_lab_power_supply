library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.clock_divider_pkg.all;

package ads_7056_pkg is

    type ads_7056_record is record
        clock_divider  : clock_divider_record;
        shift_register : std_logic_vector(17 downto 0);
        is_ready       : boolean;
    end record;

    constant init_ads7056 : ads_7056_record := (init_clock_divider(7), (others => '0'), false);

end package ads_7056_pkg;


package body ads_7056_pkg is

end package body ads_7056_pkg;
