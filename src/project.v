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

    // 1. Your actual design logic
    // The ring oscillator output is assigned to one bit of the output.
    wire rnd_out;
    ring_osc ro0 (
        .rnd(rnd_out)
    );

    // 2. Pass-through logic to prevent disconnected pins
    // This part is ONLY to satisfy the tools. It ensures every input
    // has a path to an output, so it won't be optimized away.

    // Pass the 8-bit uio_in bus directly to the uio_out bus.
    assign uio_out = uio_in;

    // Pass 7 bits of ui_in directly to 7 bits of uo_out.
    assign uo_out[7:1] = ui_in[7:1];
    
    // Combine the remaining single-bit inputs (ena, clk, rst_n, and ui_in[0])
    // with your actual ring oscillator output. The XOR logic is minimal and
    // ensures the synthesizer keeps these input pins.
    assign uo_out[0] = rnd_out ^ ui_in[0] ^ ena ^ clk ^ rst_n;

    // 3. Set I/O direction
    // Set all bidirectional pins to be inputs, since we are reading from uio_in.
    assign uio_oe = 8'b0;

endmodule