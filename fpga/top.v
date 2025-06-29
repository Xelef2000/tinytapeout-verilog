
`include "../src/project.v"
`include "clock_wizard.v"


module top(
	input                        clk_i,
	input                        rst_n,
	output                       uart_tx
);

wire [7:0] out_data;
wire chip_clk;

assign uart_tx = out_data[0];


clock_wizard clk_gen (
	.clk_in(clk_i),
	.reset_n(rst_n),
	.clk_out(chip_clk),
	.locked()
);


tt_um_Xelef2000 i_tt_um_Xelef2000 (
	.ui_in(8'b0),        // No dedicated inputs
	.uo_out(uart_tx),    // No dedicated outputs
	.uio_in(8'b0),      // No IO inputs
	.uio_out(),         // No IO outputs
	.uio_oe(),          // No IO enable outputs
	.ena(1'b1),         // Always enabled
	.clk(chip_clk),
	.rst_n(rst_n)
);




endmodule