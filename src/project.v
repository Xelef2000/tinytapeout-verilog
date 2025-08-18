/*
 * Copyright (c) 2025 Felix Niederer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include "./uart_tx.v"
`include "./ring_osc_stub.v"

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

    // All output pins must be assigned.
    assign uo_out[7:1] = 7'b0; // Assign unused bits to 0
    assign uio_out     = 8'h00;
    assign uio_oe      = 8'h00;


    ring_osc trng ( 
        .EN(ui_in[0]),
        .OUT(uo_out[0])
    );


endmodule