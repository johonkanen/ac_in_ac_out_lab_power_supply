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

    function init_aux_pwm_with_duty_cycle ( duty_cycle : integer)
        return aux_pwm_record;

    function init_aux_period_and_duty (
        period : integer;
        duty_cycle : integer)
    return aux_pwm_record;

    procedure create_aux_pwm (
        signal aux_pwm_object : inout aux_pwm_record);

    procedure start_aux_pwm (
        signal aux_pwm_object : out aux_pwm_record);

    procedure stop_aux_pwm (
        signal aux_pwm_object : out aux_pwm_record);

end package aux_pwm_pkg;

package body aux_pwm_pkg is

    procedure create_aux_pwm
    (
        signal aux_pwm_object : inout aux_pwm_record
    ) is
        alias m is aux_pwm_object;
    begin
        if m.pwm_counter > 0 then
            m.pwm_counter <= m.pwm_counter -1;
        else
            m.pwm_counter <= m.period;
        end if;

        if m.pwm_counter < m.duty_ratio then
            m.pwm_out <= '1';
        else
            m.pwm_out <= '0';
        end if;

        if not m.pwm_is_requested then
            m.pwm_counter <= 0;
            m.pwm_out <= '0';
        end if;

    end create_aux_pwm;

    procedure start_aux_pwm
    (
        signal aux_pwm_object : out aux_pwm_record
    ) is
    begin
        aux_pwm_object.pwm_is_requested <= true;
    end start_aux_pwm;

    procedure stop_aux_pwm
    (
        signal aux_pwm_object : out aux_pwm_record
    ) is
    begin
        aux_pwm_object.pwm_is_requested <= false;
    end stop_aux_pwm;

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

end package body aux_pwm_pkg;
