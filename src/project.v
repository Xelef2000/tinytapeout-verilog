/*
 * Copyright (c) 2025 Felix Niederer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include "./uart_tx.v"
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

    assign uio_out = 0;
    assign uio_oe  = 0;

    wire _unused = &{ena, clk, rst_n, uio_in, ui_in, uo_out[7:1]};


    ring_osc trng ( 
        .rnd(uo_out[0])
    );


endmodule