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

launch_runs synth_1 -jobs 32
wait_on_run synth_1

launch_runs impl_1 -jobs 32
wait_on_run impl_1

