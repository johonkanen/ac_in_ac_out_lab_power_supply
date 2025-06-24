	main_clock u0 (
		.refclk   (_connected_to_refclk_),   //   input,  width = 1,  refclk.clk
		.rst      (_connected_to_rst_),      //   input,  width = 1,   reset.reset
		.outclk_0 (_connected_to_outclk_0_)  //  output,  width = 1, outclk0.clk
	);

