`default_nettype none

`include "../src/project.v"
`include "clock_wizard.v"


module top(
	input                        clk_i,
	output                       uart_tx,
	output                       ring_out_6,
	output                       ring_out_12,
	output                       ring_out_24,
	// 7-segment display outputs
	output [6:0]                 seg,        // Segments a-g
	output                       digit_sel   // Digit select
);


 wire chip_clk;

 // Power-on reset circuit
 // Directly use a small counter based reset
 reg [7:0] por_counter = 8'd0;
 reg rst_n_reg = 1'b0;
 wire rst_n = rst_n_reg;

 always @(posedge chip_clk) begin
	if (por_counter < 8'd255) begin
		por_counter <= por_counter + 1;
		rst_n_reg <= 1'b0;
	end else begin
		rst_n_reg <= 1'b1;
	end
 end

 clk_divider i_clk_divider (
	.clk_in(clk_i),
	.reset(1'b0),  // Clock divider reset is active-high, keep it deasserted
	.clk_out(chip_clk)
 );

 wire ena = 1'b1;
 wire [7:0] ui_in = 8'h60;  // ~0.4 sec display update rate at 500kHz
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

// 7-segment display outputs
assign seg = uio_out[6:0];       // Segments a-g
assign digit_sel = uio_out[7];   // Digit select (0=low nibble, 1=high nibble)

endmodule