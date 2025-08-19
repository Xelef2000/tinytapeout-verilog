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

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ring8;
  assign uio_out = 8'b1111_1111;
  assign uio_oe  = 8'b1111_1111;

  wire ring_osc;
  wire [7:0] ring8;

  assign ring8 = {7'b0, ring_osc};

   ring_osc trng ( 
        .rnd(ring_osc)
 );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, ui_in, uio_in, 1'b0};

endmodule

