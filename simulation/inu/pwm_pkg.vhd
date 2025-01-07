
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 

package pwm_pkg is

    type pwm_record is record
        is_enabled : boolean;
        pwm_out : std_logic;
        carrier : natural range 0 to 2**16-1;
        duty : natural range 0 to 2**16-1;
    end record;

    procedure create_pwm (
        signal self : inout pwm_record;
        signal pwm_out : out std_logic);

end package pwm_pkg;

package body pwm_pkg is


    procedure create_pwm (
        signal self : inout pwm_record;
        signal pwm_out : out std_logic) is
    begin
        self.carrier <= self.carrier + 1;
        if self.carrier > 5999 then
            self.carrier <= 0;
        end if;

        if self.carrier > (5999/2 - self.duty/2) then
            pwm_out <= '1';
        end if;

        if self.carrier > (5999/2 + self.duty/2) then
            pwm_out <= '0';
        end if;

        if not self.is_enabled then
            pwm_out <= '0';
            self.carrier <= 0;
        end if;

    end create_pwm;
end package body pwm_pkg;


