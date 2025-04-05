

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package pwm_pkg is
    type pwm_record is record
        carrier_max : natural range 0 to 2**16-1;
        carrier     : natural range 0 to 2**16-1;
        duty        : natural range 0 to 2**16-1;
        pwm         : std_logic                 ;
        enabled : boolean;
    end record;
    constant init_pwm : pwm_record := (1000 , 0 , 100 , '0' , false);

    procedure create_pwm (signal self : inout pwm_record
                          ;signal pwm_out : out std_logic
                         );

end package pwm_pkg;

package body pwm_pkg is

    procedure create_pwm (signal self : inout pwm_record
                          ;signal pwm_out : out std_logic
                         )
    is
    begin
        if self.carrier < self.carrier_max
        then
            self.carrier <= self.carrier + 1;
        else
            self.carrier <= 0;
        end if;

        self.pwm <= '1';
        if self.carrier < self.carrier_max/2 - self.duty/2
        then
            self.pwm <= '0';
        end if;

        if self.carrier > self.carrier_max/2 + self.duty/2
        then
            self.pwm <= '0';
        end if;

        if self.enabled then
        end if;
    end procedure;

end package body;

-------------------------------------------------------------------
---------------------------
