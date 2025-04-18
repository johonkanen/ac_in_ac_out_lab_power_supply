variable this_file_path [ file dirname [ file normalize [ info script ] ] ] 
variable build_path ./
source $this_file_path/control_card_build_scripts/init_build_environment.tcl

set source_folder $this_file_path/../source

create_project my_project ./my_project -part xc7s15ftgb196-2 -force
set_property target_language VHDL [current_project]
set_param general.maxThreads 16

source $this_file_path/gen_main_pll.tcl
#generate_ip_module main_pll
#
source $this_file_path/vhdl_sources.tcl

set_property top s7_top [current_fileset]

add_vhdl_file_to_project $this_file_path/s7_top.vhd

synth_design -rtl -rtl_skip_mlo -name rtl_1

source $this_file_path/set_io.tcl
source $this_file_path/control_card_build_scripts/place_io.tcl

close [ open $build_path/constraints.xdc w ]
add_files -fileset constrs_1 $build_path/constraints.xdc
set_property target_constrs_file $build_path/constraints.xdc [current_fileset -constrset]
save_constraints -force
launch_runs synth_1 -jobs 32
wait_on_run synth_1

launch_runs impl_1 -jobs 32
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream -jobs 32
open_run impl_1 -name impl_1

# #VCCO(zero) = IO = 2.5V || 3.3V, GND IO bank0 = 1.8v
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.Config.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

write_bitstream -force jihuu.bit
write_cfgmem -force  -format mcs -size 2 -interface SPIx4        \
    -loadbit "up 0x0 jihuu.bit" \
    -file "jihuu.mcs"

