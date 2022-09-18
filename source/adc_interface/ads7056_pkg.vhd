library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.clock_divider_pkg.all;

package ads_7056_pkg is

    type ads_7056_record is record
        clock_divider          : clock_divider_record;
        shift_register         : std_logic_vector(17 downto 0);
        is_ready               : boolean;
        chip_select            : std_logic;
        ads7056_is_initialized : boolean;
    end record;

    function init_ads7056 return ads_7056_record;

end package ads_7056_pkg;


package body ads_7056_pkg is

    constant initial_values_for_ads7056 : ads_7056_record := ( init_clock_divider(7), (others => '0'), false, '1', false);
--------------------------------------------------
    function init_ads7056 return ads_7056_record
    is
    begin
       return initial_values_for_ads7056; 
    end init_ads7056;
------------------------------------------------------------------------
    function init_ads7056
    (
        core_clocks_in_adc_clock : integer range 2 to 1024
    )
    return ads_7056_record
    is
        variable init_values : ads_7056_record := initial_values_for_ads7056;
    begin

        init_values := (init_clock_divider(core_clocks_in_adc_clock) ,
                        (others => '0')                              ,
                        false                                        ,
                        '1'                                          ,
                        false);

        return init_values;
        
    end init_ads7056;
------------------------------------------------------------------------
    procedure create_ads7056
    (
        signal ads7056_object : inout ads_7056_record
    ) is
        alias m is ads7056_object;
    begin
        m.chip_select <= '1';
        create_clock_divider(m.clock_divider);

        if m.clock_divider.clock_counter > 0 then
            m.chip_select <= '0';
        end if;
    end create_ads7056;
------------------------------------------------------------------------
    procedure request_ad_conversion
    (
        signal ads7056_object : inout ads_7056_record;
        number_of_adc_clocks : integer
    ) is
    begin
       request_clock_divider(ads7056_object.clock_divider, number_of_adc_clocks);
       ads7056_object.chip_select <= '0';
    end request_ad_conversion;
------------------------------
    procedure request_ad_conversion
    (
        signal ads7056_object : inout ads_7056_record
    ) is
    begin
        request_ad_conversion(ads7056_object, 18);
    end request_ad_conversion;
------------------------------------------------------------------------
    procedure initialize_ads_7056
    (
        signal ads7056_object : inout ads_7056_record
    ) is
    begin
        if ads7056_object.ads7056_is_initialized then
            request_ad_conversion(ads7056_object, 60);
        else
            request_ad_conversion(ads7056_object, 24);
            ads7056_object.ads7056_is_initialized <= true;
        end if;
        
    end initialize_ads_7056;
------------------------------------------------------------------------
end package body ads_7056_pkg;
