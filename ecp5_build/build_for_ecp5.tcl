variable tcl_path [ file dirname [ file normalize [ info script ] ] ] 
puts $tcl_path
set outputDir ./output
set source_folder $tcl_path/../source
file mkdir $outputDir

set files [glob -nocomplain "$outputDir/*"]
if {[llength $files] != 0} {
    # clear folder contents
    puts "deleting contents of $outputDir"
    file delete -force {*}[glob -directory $outputDir *]; 
}


prj_project new -name hvhdl_example \
    -impl "impl1" \
    -dev LFE5U-12F-8BG381C \
    -impl_dir $outputDir \
    -synthesis "Synplify" \

prj_src add $tcl_path/IP/ip/ip.sbx

prj_strgy set_value -strategy Strategy1 syn_arrange_vhdl_files=True
prj_strgy set_value -strategy Strategy1 par_pathbased_place=On
prj_strgy set_value -strategy Strategy1 map_reg_retiming=True
prj_strgy set_value -strategy Strategy1 syn_update_compile_pt_timing_data=True 
#do not change area setting, synthesis will crash if syn_area = true
prj_strgy set_value -strategy Strategy1 syn_area=False
#If retiming is not on, Synplify will crash for some reason
prj_strgy set_value -strategy Strategy1 map_timing_driven=True map_timing_driven_node_replication=True map_timing_driven_pack=True
prj_strgy set_value -strategy Strategy1 syn_res_sharing=False
prj_strgy set_value -strategy Strategy1 syn_allow_dup_modules=True
prj_strgy set_value -strategy Strategy1 syn_frequency=120
prj_strgy set_value -strategy Strategy1 syn_fsm_encoding=True
prj_strgy set_value -strategy Strategy1 syn_vhdl2008=True
prj_strgy set_value -strategy Strategy1 {syn_pipelining_retiming=Pipelining and Retiming}
prj_strgy set_value -strategy Strategy1 syn_output_netlist_format=VHDL
prj_strgy set_value -strategy Strategy1 map_io_reg=Auto map_overmap_device=True

prj_strgy set_value -strategy Strategy1 par_stop_zero=True

proc add_vhdl_file_to_project {vhdl_file} {
    prj_src add $vhdl_file
}

proc add_vhdl_file_to_library {vhdl_file library} {
    prj_src add $vhdl_file -work $library
}

add_vhdl_file_to_project $tcl_path/ecp5_top.vhd

source $tcl_path/vhdl_sources.tcl

prj_src add -exclude $tcl_path/constraints.lpf
prj_src enable $tcl_path/constraints.lpf
prj_src remove hvhdl_example.lpf
file delete -force hvhdl_example.lpf

prj_run Synthesis -impl impl1
prj_run Translate -impl impl1
prj_run Map -impl impl1
prj_run PAR -impl impl1
prj_run Export -impl impl1 -task Bitgen
prj_run Export -impl impl1 -task Promgen
prj_project save
