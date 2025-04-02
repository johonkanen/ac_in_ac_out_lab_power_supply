create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name main_pll
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {312.5} \
  CONFIG.CLKOUT1_JITTER {193.774} \
  CONFIG.CLKOUT1_PHASE_ERROR {203.212} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {128} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {31.000} \
  CONFIG.MMCM_CLKIN1_PERIOD {31.250} \
  CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {7.750} \
  CONFIG.PRIM_IN_FREQ {32} \
  CONFIG.USE_LOCKED {false} \
  CONFIG.USE_RESET {false} \
] [get_ips main_pll]

generate_target all [get_files  ./my_project/my_project.srcs/sources_1/ip/main_pll/main_pll.xci]
export_ip_user_files -of_objects [get_files ./my_project/my_project.srcs/sources_1/ip/main_pll/main_pll.xci] -no_script -sync -force -quiet
