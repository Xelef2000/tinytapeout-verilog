`default_nettype none
`include "./ring_osc.v"

module tt_um_Xelef2000 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


    wire rnd_out;
    ring_osc ro0 (
        .rnd(rnd_out),
        .en(ena)
    );


    assign uio_out = uio_in;

    assign uo_out[7:1] = ui_in[7:1];


    

    assign uo_out[0] = rnd_out ^ ui_in[0] ^ clk ^ rst_n;


    assign uio_oe = 8'b0;

endmodule