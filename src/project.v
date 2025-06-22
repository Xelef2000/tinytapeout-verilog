/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include "uart_tx.v"



module tt_um_Xelef2000 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire TX;
  assign uo_out[0] = TX; 
  assign uo_out[7:1] = 0; // Unused outputs


  localparam BIT_RATE = 9600; // bits/sec
  localparam PAYLOAD_BITS = 8; // Number of data bits in the UART packet
  localparam CLK_HZ = 20_000_000; // Clock frequency in h

  wire uart_tx_en;
  wire uart_tx_busy; 
  wire [PAYLOAD_BITS-1:0] uart_tx_data;

  assign TX = 0; // test

  assign uart_tx_en = 1; // Enable UART transmission
  assign uart_tx_data = 8'h55; // Example data to send (0x55)

    uart_tx #(
        .BIT_RATE(BIT_RATE),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .CLK_HZ(CLK_HZ)
    ) i_uart_tx(
        .clk(clk),              // Use the divided system clock
        .resetn(rst_n),            // Active low reset
        .uart_txd(TX),              // Connect to the TX output pin
        .uart_tx_en(uart_tx_en),
        .uart_tx_busy(uart_tx_busy),
        .uart_tx_data(uart_tx_data)
    );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, uart_tx_busy};

endmodule
