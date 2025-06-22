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
  localparam CLK_HZ = 20_000_000; // Clock frequency in Hz

  localparam MSG_LENGTH = 14;
  reg [7:0] message [0:MSG_LENGTH-1];
  
  initial begin
    message[0]  = 8'h68; // 'h'
    message[1]  = 8'h65; // 'e'
    message[2]  = 8'h6C; // 'l'
    message[3]  = 8'h6C; // 'l'
    message[4]  = 8'h6F; // 'o'
    message[5]  = 8'h20; // ' '
    message[6]  = 8'h77; // 'w'
    message[7]  = 8'h6F; // 'o'
    message[8]  = 8'h72; // 'r'
    message[9]  = 8'h6C; // 'l'
    message[10] = 8'h64; // 'd'
    message[11] = 8'h0D; // '\r'
    message[12] = 8'h0A; // '\n'
    message[13] = 8'h00; // null terminator 
  end

  reg [3:0] char_index;
  reg uart_tx_en;
  wire uart_tx_busy;
  reg [7:0] uart_tx_data;
  reg prev_uart_tx_busy;

  reg [24:0] delay_counter;
  localparam [24:0] DELAY_CYCLES = 25'd20_000_000; // 1 second delay at 20MHz
  reg in_delay;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      char_index <= 0;
      uart_tx_en <= 0;
      uart_tx_data <= 0;
      prev_uart_tx_busy <= 0;
      delay_counter <= 0;
      in_delay <= 0;
    end else begin
      prev_uart_tx_busy <= uart_tx_busy;
      
      if (in_delay) begin
        if (delay_counter < DELAY_CYCLES) begin
          delay_counter <= delay_counter + 1;
        end else begin
          in_delay <= 0;
          delay_counter <= 0;
          char_index <= 0;
        end
      end else begin
        if (!uart_tx_busy && prev_uart_tx_busy) begin
          char_index <= char_index + 1;
        end
        
        if (char_index < MSG_LENGTH - 1) begin // -1 to skip null terminator
          if (!uart_tx_busy) begin
            uart_tx_data <= message[char_index];
            uart_tx_en <= 1;
          end else begin
            uart_tx_en <= 0;
          end
        end else begin
          uart_tx_en <= 0;
          in_delay <= 1;
        end
      end
    end
  end

  uart_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_HZ)
  ) i_uart_tx(
    .clk(clk),
    .resetn(rst_n),
    .uart_txd(TX),
    .uart_tx_en(uart_tx_en),
    .uart_tx_busy(uart_tx_busy),
    .uart_tx_data(uart_tx_data)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in};

endmodule