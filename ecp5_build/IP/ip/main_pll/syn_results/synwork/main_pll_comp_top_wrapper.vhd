--
-- Synopsys
-- Vhdl wrapper for top level design, written on Mon Mar 31 05:57:04 2025
--
library ieee;
use ieee.std_logic_1164.all;
library ecp5u;
use ecp5u.components.all;

entity wrapper_for_main_pll is
   port (
      CLKI : in std_logic;
      CLKOP : out std_logic
   );
end wrapper_for_main_pll;

architecture structure of wrapper_for_main_pll is

component main_pll
 port (
   CLKI : in std_logic;
   CLKOP : out std_logic
 );
end component;

signal tmp_CLKI : std_logic;
signal tmp_CLKOP : std_logic;

begin

tmp_CLKI <= CLKI;

CLKOP <= tmp_CLKOP;



u1:   main_pll port map (
		CLKI => tmp_CLKI,
		CLKOP => tmp_CLKOP
       );
end structure;
