library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package long_multiplier_pkg is
------------------------------------------------------------------------
    type long_multiplier_record is record
        process_counter              : integer;
        multiplier_process_counter   : integer;
        left                         : unsigned(31 downto 0);
        right                        : unsigned(31 downto 0);
        result                       : unsigned(31 downto 0);
        long_result                  : unsigned(63 downto 0);
        multiplier_is_ready          : boolean;
        long_multiplier_is_requested : boolean;
        long_multiplier_is_ready     : boolean;
    end record;

    constant init_long_multiplier : long_multiplier_record := (0,0, (others => '0'), (others => '0'), (others => '0'), (others => '0'), false, false, false);
------------------------------------------------------------------------
    procedure create_long_multiplier (
        signal long_multiplier_object : inout long_multiplier_record);
------------------------------------------------------------------------
    procedure request_long_multiplier (
        signal long_multiplier_object : out long_multiplier_record;
        left, right : unsigned);
------------------------------------------------------------------------
    function long_multiplier_is_ready (long_multiplier_object : long_multiplier_record)
        return boolean;
------------------------------------------------------------------------
end package long_multiplier_pkg;

package body long_multiplier_pkg is
------------------------------------------------------------------------
    procedure increment
    (
        signal counter : inout integer
    ) is
    begin
        counter <= counter +  1;
    end increment;
------------------------------------------------------------------------
    procedure create_long_multiplier 
    (
        signal long_multiplier_object : inout long_multiplier_record
    ) 
    is
        -- alias long_multiplier_is_requested is long_multiplier_object.long_multiplier_is_requested;
        -- alias multiplier_result is long_multiplier_object.multiplier_result;

        alias process_counter              is  long_multiplier_object.process_counter              ;
        alias multiplier_process_counter   is  long_multiplier_object.multiplier_process_counter   ;
        alias left                         is  long_multiplier_object.left                         ;
        alias right                        is  long_multiplier_object.right                        ;
        alias multiplier_result            is  long_multiplier_object.result                       ;
        alias multiplier_is_ready          is  long_multiplier_object.multiplier_is_ready          ;
        alias long_multiplier_is_requested is  long_multiplier_object.long_multiplier_is_requested ;
        alias long_multiplier_is_ready     is  long_multiplier_object.long_multiplier_is_ready;
        
        alias atest is long_multiplier_object.long_result;

        variable a0 : unsigned(15 downto 0) := (others => '0');
        variable a1 : unsigned(15 downto 0) := (others => '0');

        variable b0 : unsigned(15 downto 0) := (others => '0');
        variable b1 : unsigned(15 downto 0) := (others => '0');
    begin
        long_multiplier_is_requested <= false;

        multiplier_is_ready <= false;
        CASE multiplier_process_counter is
            WHEN 0 =>
                multiplier_result <= a1*b1;
                multiplier_is_ready <= true;
                increment(multiplier_process_counter);
            WHEN 1 =>
                multiplier_result <= a1*b0;
                multiplier_is_ready <= true;
                increment(multiplier_process_counter);
            WHEN 2 =>
                multiplier_result <= a0*b1;
                multiplier_is_ready <= true;
                increment(multiplier_process_counter);
            WHEN 3 =>
                multiplier_result <= a0*b0;
                multiplier_is_ready <= true;
                increment(multiplier_process_counter);
            WHEN others => -- do nothing
        end CASE; --multiplier_process_counter

        long_multiplier_is_ready <= false;
        CASE process_counter is
            WHEN 0 => 
                if multiplier_is_ready then
                    atest(31 downto 0)   <= multiplier_result;
                    increment(process_counter);
                end if;

            WHEN 1 => 
                atest(31+16 downto 16) <= multiplier_result+atest(31 downto 16);
                increment(process_counter);

            WHEN 2 => 
                atest(31+16 downto 16) <= multiplier_result+atest(31+16 downto 16);
                increment(process_counter);

            WHEN 3 => 
                long_multiplier_is_ready <= true;
                atest(63 downto 32) <= multiplier_result+atest(31+16 downto 32);
                increment(process_counter);

            WHEN others =>
        end CASE; --process_counter

    end procedure;

------------------------------------------------------------------------
    procedure request_long_multiplier
    (
        signal long_multiplier_object : out long_multiplier_record;
        left, right : unsigned
    ) is
    begin
        long_multiplier_object.long_multiplier_is_requested <= true;
        long_multiplier_object.left <= left;
        long_multiplier_object.right <= right;
        
    end request_long_multiplier;

------------------------------------------------------------------------
    function long_multiplier_is_ready
    (
        long_multiplier_object : long_multiplier_record
    )
    return boolean
    is
    begin
        return long_multiplier_object.long_multiplier_is_ready;
    end long_multiplier_is_ready;

------------------------------------------------------------------------
end package body long_multiplier_pkg;
