library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package aux_pwm_pkg is

    type aux_pwm_record is record
        pwm_is_requested : boolean;
        pwm_counter : integer range 0 to 2**16-1;
        duty_ratio : integer range 0 to 2**16-1;
        period : integer range 0 to 2**16-1;
        pwm_out : std_logic;
    end record;

    constant init_aux_pwm : aux_pwm_record := (false, 0, 0, 500, '0');

------------------------------------------------------------------------
    function init_aux_pwm_with_duty_cycle ( duty_cycle : integer)
        return aux_pwm_record;

------------------------------------------------------------------------
    function init_aux_period_and_duty (
        period : integer;
        duty_cycle : integer)
    return aux_pwm_record;

------------------------------------------------------------------------
    procedure create_aux_pwm (
        signal self : inout aux_pwm_record);

    function create_aux_pwm(self : aux_pwm_record) return aux_pwm_record;
------------------------------------------------------------------------
    procedure start_aux_pwm (
        signal self : out aux_pwm_record);

------------------------------------------------------------------------
    procedure stop_aux_pwm (
        signal self : out aux_pwm_record);

------------------------------------------------------------------------
end package aux_pwm_pkg;

package body aux_pwm_pkg is

------------------------------------------------------------------------
    function create_aux_pwm(self : aux_pwm_record) return aux_pwm_record is
        variable retval : aux_pwm_record := self;
    begin
        if self.pwm_counter > 0 then
            retval.pwm_counter := self.pwm_counter -1;
        else
            retval.pwm_counter := self.period;
        end if;

        if self.pwm_counter < self.duty_ratio then
            retval.pwm_out := '1';
        else
            retval.pwm_out := '0';
        end if;

        if not self.pwm_is_requested then
            retval.pwm_counter := 0;
            retval.pwm_out := '0';
        end if;

        return self;

    end function;

    procedure create_aux_pwm
    (
        signal self : inout aux_pwm_record
    ) is
    begin
        if self.pwm_counter > 0 then
            self.pwm_counter <= self.pwm_counter -1;
        else
            self.pwm_counter <= self.period;
        end if;

        if self.pwm_counter < self.duty_ratio then
            self.pwm_out <= '1';
        else
            self.pwm_out <= '0';
        end if;

        if not self.pwm_is_requested then
            self.pwm_counter <= 0;
            self.pwm_out <= '0';
        end if;

    end create_aux_pwm;

------------------------------------------------------------------------
    procedure start_aux_pwm
    (
        signal self : out aux_pwm_record
    ) is
    begin
        self.pwm_is_requested <= true;
    end start_aux_pwm;

------------------------------------------------------------------------
    procedure stop_aux_pwm
    (
        signal self : out aux_pwm_record
    ) is
    begin
        self.pwm_is_requested <= false;
    end stop_aux_pwm;

------------------------------------------------------------------------
    function init_aux_pwm_with_duty_cycle
    (
        duty_cycle : integer
    )
    return aux_pwm_record
    is
        variable returned_value : aux_pwm_record := init_aux_pwm;
    begin
        returned_value.duty_ratio := duty_cycle;
        return returned_value;
    end init_aux_pwm_with_duty_cycle;

------------------------------------------------------------------------
    function init_aux_period_and_duty
    (
        period : integer;
        duty_cycle : integer
    )
    return aux_pwm_record
    is
        variable returned_value : aux_pwm_record := init_aux_pwm_with_duty_cycle(duty_cycle);
    begin
        returned_value.period := period;
        return returned_value;
    end init_aux_period_and_duty;

------------------------------------------------------------------------
end package body aux_pwm_pkg;
