module main_clock (
		input  wire  refclk,   //  refclk.clk,   The reference clock source that drives the I/O PLL.
		input  wire  rst,      //   reset.reset, The asynchronous reset port for the output clocks. Drive this port high to reset all output clocks to the value of 0.
		output wire  outclk_0  // outclk0.clk,   Output clock Channel 0 from I/O PLL.
	);
endmodule

