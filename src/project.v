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
    // ---- Tie off unused inputs ----
    // Prevent floating pins
    wire _unused = &{ ui_in, uio_in, ena, clk, rst_n, 1'b0 };

    // ---- Drive unused outputs ----
    assign uio_out = 8'b0;   // all zeros
    assign uio_oe  = 8'b0;   // disable all
    assign uo_out[7:1] = 7'b0; // leave only uo_out[0] connected

    // ---- Your RO instance ----
    wire rnd;
    ring_osc ro0 (
        .rnd(rnd)
    );

    // Connect the random output to one pin
    assign uo_out[0] = rnd;

endmodule