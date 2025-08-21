
`include "../src/project.v"
`include "clock_wizard.v"


module top(
	input                        clk_i,
	output                       uart_tx,
	output                       ring_out_6,
	output                       ring_out_12,
	output                       ring_out_24
);


 wire chip_clk;
 wire rst_n = 1'b1; 

 clk_divider i_clk_divider (
	.clk_in(clk_i),
	.reset(rst_n),
	.clk_out(chip_clk)
 );

 wire ena = 1'b1; 
 wire [7:0] ui_in = 8'b0; 
 wire [7:0] uio_in = 8'b0; 
 wire [7:0] uio_out; 
 wire [7:0] uio_oe; 
 wire [7:0] uo_out; 




tt_um_Xelef2000 i_tt_um_Xelef2000 (
	.ui_in(ui_in),        
	.uo_out(uo_out), 
	.uio_in(uio_in),      
	.uio_out(uio_out),         
	.uio_oe(uio_oe),        
	.ena(ena),         
	.clk(chip_clk),
	.rst_n(rst_n)
);


assign uart_tx = uo_out[0];
assign ring_out_6 = uo_out[1];
assign ring_out_12 = uo_out[2];
assign ring_out_24 = uo_out[3];

endmodule