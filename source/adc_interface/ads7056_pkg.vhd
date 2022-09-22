library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.clock_divider_pkg.all;

package ads7056_pkg is

    type ads7056_record is record
        clock_divider   : clock_divider_record;
        shift_register  : std_logic_vector(17 downto 0);
        measurement     : unsigned(13 downto 0);
        is_ready        : boolean;
        chip_select     : std_logic;
        chip_select_out : std_logic;
        is_initialized  : boolean;
    end record;

    function init_ads7056 return ads7056_record;

    function init_ads7056 ( core_clocks_in_adc_clock : integer range 2 to 1024)
        return ads7056_record;

------------------------------------------------------------------------
    procedure create_ads7056 (
        signal ads7056_object : inout ads7056_record;
        ad_input_io : std_logic );
------------------------------------------------------------------------
    procedure request_ad_conversion (
        signal ads7056_object : inout ads7056_record);
------------------------------------------------------------------------
    procedure initialize_ads7056 (
        signal ads7056_object : inout ads7056_record);
------------------------------------------------------------------------
    function get_ad_measurement ( ads7056_object : ads7056_record)
        return integer;
------------------------------------------------------------------------
    function ads7056_is_ready ( ads7056_object : ads7056_record)
        return boolean;
------------------------------------------------------------------------
    function ads7056_has_been_initialized ( ads7056_object : ads7056_record)
        return boolean;
------------------------------------------------------------------------
    function ad_converter_is_busy ( ads7056_object : ads7056_record)
        return boolean;
------------------------------------------------------------------------
end package ads7056_pkg;


package body ads7056_pkg is

    constant initial_values_for_ads7056 : ads7056_record := ( init_clock_divider(7), (others => '0'), (others => '0'), false, '1', '1', false);
--------------------------------------------------
    function init_ads7056 return ads7056_record
    is
    begin
       return initial_values_for_ads7056; 
    end init_ads7056;
------------------------------------------------------------------------
    function init_ads7056
    (
        core_clocks_in_adc_clock : integer range 2 to 1024
    )
    return ads7056_record
    is
        variable init_values : ads7056_record := initial_values_for_ads7056;
    begin

        init_values := (init_clock_divider(core_clocks_in_adc_clock) ,
                        (others => '0')                              ,
                        (others => '0')                              ,
                        false                                        ,
                        '1'                                          ,
                        '1'                                          ,
                        false);

        return init_values;
        
    end init_ads7056;
------------------------------------------------------------------------
    procedure create_ads7056
    (
        signal ads7056_object : inout ads7056_record;
        ad_input_io : std_logic 
    ) is
        alias m is ads7056_object;
    begin
        m.chip_select <= '1';
        create_clock_divider(m.clock_divider);

        if m.clock_divider.clock_counter > 0 then

            if data_delivered_on_rising_edge(m.clock_divider) then
                m.shift_register <= m.shift_register(m.shift_register'left-1 downto 0) & ad_input_io;
            end if;

            m.chip_select <= '0';
        end if;
        m.chip_select_out <= m.chip_select;
        m.is_ready <= m.chip_select = '1' and m.chip_select_out = '0';

        if m.is_ready then
            m.measurement <= unsigned(m.shift_register(15 downto 2));
        end if;
    end create_ads7056;
------------------------------------------------------------------------
    procedure request_ad_conversion
    (
        signal ads7056_object : inout ads7056_record;
        number_of_adc_clocks : integer
    ) is
    begin
        if not ad_converter_is_busy(ads7056_object) then
           request_clock_divider(ads7056_object.clock_divider, number_of_adc_clocks);
           ads7056_object.chip_select <= '0';
       end if;
    end request_ad_conversion;
------------------------------
    procedure request_ad_conversion
    (
        signal ads7056_object : inout ads7056_record
    ) is
    begin
        request_ad_conversion(ads7056_object, 18);
    end request_ad_conversion;
------------------------------------------------------------------------
    function ads7056_has_been_initialized
    (
        ads7056_object : ads7056_record
    )
    return boolean
    is
    begin
        return ads7056_object.is_initialized;
    end ads7056_has_been_initialized;
------------------------------------------------------------------------
    procedure initialize_ads7056
    (
        signal ads7056_object : inout ads7056_record
    ) is
    begin
        if ads7056_has_been_initialized(ads7056_object) then
            request_ad_conversion(ads7056_object, 60);
        else
            request_ad_conversion(ads7056_object, 24);
            ads7056_object.is_initialized <= true;
        end if;
        
    end initialize_ads7056;
------------------------------------------------------------------------
    function get_ad_measurement
    (
        ads7056_object : ads7056_record
    )
    return integer
    is
    begin

        return to_integer(ads7056_object.measurement);
        
    end get_ad_measurement;
------------------------------------------------------------------------
    function ads7056_is_ready
    (
        ads7056_object : ads7056_record
    )
    return boolean
    is
    begin
        return ads7056_object.is_ready;
    end ads7056_is_ready;
------------------------------------------------------------------------
    function ad_converter_is_busy
    (
        ads7056_object : ads7056_record
    )
    return boolean
    is
        alias m is ads7056_object;
    begin
        return (m.chip_select = '0') or (m.chip_select = '1' and m.chip_select_out = '0');
    end ad_converter_is_busy;
------------------------------------------------------------------------
end package body ads7056_pkg;
