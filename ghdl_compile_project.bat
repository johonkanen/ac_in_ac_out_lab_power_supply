echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source

ghdl -a --ieee=synopsys --std=08 efinix_build/efinix_system_clocks_pkg.vhd

        ghdl -a --ieee=synopsys --std=08 source/system_control/system_components/power_electronics/power_electronics_pkg.vhd
    ghdl -a --ieee=synopsys --std=08 source/system_control/system_components/system_components_pkg.vhd
ghdl -a --ieee=synopsys --std=08 source/system_control/system_control_pkg.vhd
