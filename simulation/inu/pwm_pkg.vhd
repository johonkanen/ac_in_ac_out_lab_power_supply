
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 

package pwm_pkg is

    type pwm_record is record
        is_enabled       : boolean;
        pwm_out          : std_logic;
        carrier          : natural range 0 to 2**16-1;
        carrier_init     : natural range 0 to 2**16-1;
        period_in_clocks : natural range 0 to 2**16-1;
        duty             : natural range 0 to 2**16-1;
    end record;

    function init_pwm return pwm_record;
    function init_pwm(period_in_clocks : natural
        ; ontime_in_clocks : natural
        ; initial_carrier : natural) 
        return pwm_record;

    procedure create_pwm (
        signal self : inout pwm_record;
        signal pwm_out : out std_logic);

end package pwm_pkg;

package body pwm_pkg is

    function init_pwm return pwm_record is
    begin
        return (
            is_enabled => false
            , pwm_out => '0'
            , carrier => 0
            , carrier_init => 0
            , period_in_clocks => 5999
            , duty => 100);
    end function;

    function init_pwm(period_in_clocks : natural; ontime_in_clocks : natural; initial_carrier : natural) return pwm_record is
    begin
        return (
            is_enabled => false
            , pwm_out => '0'
            , carrier => initial_carrier
            , carrier_init => initial_carrier
            , period_in_clocks => period_in_clocks
            , duty => ontime_in_clocks);

    end function;


    procedure create_pwm (
        signal self : inout pwm_record;
        signal pwm_out : out std_logic) is
    begin
        self.carrier <= self.carrier + 1;
        if self.carrier > self.period_in_clocks then
            self.carrier <= 0;
        end if;

        if self.carrier > (self.period_in_clocks/2 - self.duty/2) then
            pwm_out <= '1';
        end if;

        if self.carrier > (self.period_in_clocks/2 + self.duty/2) then
            pwm_out <= '0';
        end if;

        if not self.is_enabled then
            pwm_out <= '0';
            self.carrier <= self.carrier_init;
        end if;

    end create_pwm;
end package body pwm_pkg;
