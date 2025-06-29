/*
 * Copyright (c) 2025 Felix Niederer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include "./uart_tx.v"

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

    // Parameters
    localparam CLK_HZ = 500000;
    localparam UART_BIT_RATE = 9600;
    localparam PAYLOAD_BITS = 8;
    
    // Hello World string parameters
    localparam MSG_LENGTH = 13;  // "Hello World!\n" = 13 characters
    localparam CHAR_BITS = 4;    // Need 4 bits to count up to 13
    
    // Delay parameters for repeating the message
    localparam REPEAT_DELAY_CYCLES = CLK_HZ;  // 1 second delay at 500kHz
    localparam DELAY_COUNTER_BITS = 20;       // Enough bits for 1M cycles

    // Fixed pin assignments
    assign uio_oe = 8'b11111111;   // All IOs as outputs
    assign uio_out = 8'b00000000;  // All IOs low

    // UART signals
    wire uart_tx;
    wire uart_tx_busy;
    reg uart_tx_en;
    reg [7:0] uart_tx_data;

    // State machine signals
    reg [CHAR_BITS-1:0] char_index;
    reg [DELAY_COUNTER_BITS-1:0] delay_counter;
    
    // State machine states
    localparam STATE_IDLE = 2'b00;
    localparam STATE_SEND_CHAR = 2'b01;
    localparam STATE_WAIT_TX = 2'b10;
    localparam STATE_DELAY = 2'b11;
    


    // UART transmitter instance
    uart_tx #(
        .BIT_RATE(UART_BIT_RATE),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .CLK_HZ(CLK_HZ)
    ) i_uart_tx (
        .clk(clk),              
        .resetn(rst_n),     
        .uart_txd(uart_tx),             
        .uart_tx_en(uart_tx_en),
        .uart_tx_busy(uart_tx_busy),
        .uart_tx_data(uart_tx_data)
    );

    // Output assignments
    assign uo_out[0] = uart_tx;           // UART TX on output pin 0
    assign uo_out[7:1] = 7'b0000000;     // Other outputs tied low

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in, uio_in};

endmodule