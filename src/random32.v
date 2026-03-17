`default_nettype none

`include "ring_osc_5.v"
`include "ring_osc_11.v"
`include "ring_osc_23.v"

module random32 (
    input  wire       clk,      // system clock
    input  wire       rst_n,    // active-low synchronous reset
    input  wire       en,       // enable
    output reg [31:0] rnd_out,  // random 32-bit number
    output reg        ready,    // high for 1 cycle when rnd_out is fresh

    output wire       ring_out_6,
    output wire       ring_out_12,
    output wire       ring_out_24
);

    // ===================================================================
    // Section 1: Entropy Source - Ring Oscillators
    // ===================================================================
    wire ring_bit_5, ring_bit_11, ring_bit_23;

    // Ring oscillators are enabled by the 'en' signal
    ring_osc_5 u_ring6 (.en(en), .rnd(ring_bit_5));
    ring_osc_11 u_ring12 (.en(en), .rnd(ring_bit_11));
    ring_osc_23 u_ring24 (.en(en), .rnd(ring_bit_23));

    assign ring_out_6  = ring_bit_5;
    assign ring_out_12 = ring_bit_11;
    assign ring_out_24 = ring_bit_23;

    // ===================================================================
    // Section 1b: Jitter Counters (Option 3)
    // ===================================================================
    // Count transitions of each ring oscillator over a sampling window.
    // The LSBs capture jitter-based entropy.

    // Synchronizers for each ring oscillator (to detect edges)
    reg ring5_sync1, ring5_sync2, ring5_prev;
    reg ring11_sync1, ring11_sync2, ring11_prev;
    reg ring23_sync1, ring23_sync2, ring23_prev;

    // Edge detection
    wire ring5_edge  = ring5_sync2  ^ ring5_prev;
    wire ring11_edge = ring11_sync2 ^ ring11_prev;
    wire ring23_edge = ring23_sync2 ^ ring23_prev;

    // Jitter counters (count edges within sampling window)
    reg [7:0] jitter_cnt_5;
    reg [7:0] jitter_cnt_11;
    reg [7:0] jitter_cnt_23;

    // Prescaler counter (Option 2) - sample every 64 clocks
    reg [5:0] prescaler;
    wire sample_tick = (prescaler == 6'd63);

    // Latched jitter LSBs at sample tick
    reg jitter_bit;
    reg jitter_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            ring5_sync1  <= 1'b0; ring5_sync2  <= 1'b0; ring5_prev  <= 1'b0;
            ring11_sync1 <= 1'b0; ring11_sync2 <= 1'b0; ring11_prev <= 1'b0;
            ring23_sync1 <= 1'b0; ring23_sync2 <= 1'b0; ring23_prev <= 1'b0;
            jitter_cnt_5  <= 8'd0;
            jitter_cnt_11 <= 8'd0;
            jitter_cnt_23 <= 8'd0;
            prescaler     <= 6'd0;
            jitter_bit    <= 1'b0;
            jitter_valid  <= 1'b0;
        end else if (en) begin
            // Synchronize ring oscillator outputs
            ring5_sync1  <= ring_bit_5;  ring5_sync2  <= ring5_sync1;
            ring11_sync1 <= ring_bit_11; ring11_sync2 <= ring11_sync1;
            ring23_sync1 <= ring_bit_23; ring23_sync2 <= ring23_sync1;

            // Store previous values for edge detection
            ring5_prev  <= ring5_sync2;
            ring11_prev <= ring11_sync2;
            ring23_prev <= ring23_sync2;

            // Count edges
            jitter_cnt_5  <= jitter_cnt_5  + {7'd0, ring5_edge};
            jitter_cnt_11 <= jitter_cnt_11 + {7'd0, ring11_edge};
            jitter_cnt_23 <= jitter_cnt_23 + {7'd0, ring23_edge};

            // Prescaler
            prescaler <= prescaler + 1;
            jitter_valid <= 1'b0;

            if (sample_tick) begin
                // XOR the LSBs of all three jitter counters
                // Also XOR some higher bits for more entropy mixing
                jitter_bit <= jitter_cnt_5[0] ^ jitter_cnt_5[1] ^
                              jitter_cnt_11[0] ^ jitter_cnt_11[1] ^
                              jitter_cnt_23[0] ^ jitter_cnt_23[1];
                jitter_valid <= 1'b1;
                // Reset counters for next window
                jitter_cnt_5  <= 8'd0;
                jitter_cnt_11 <= 8'd0;
                jitter_cnt_23 <= 8'd0;
            end
        end
    end

    // Use jitter-based entropy instead of raw synchronized bit
    wire rnd_sync = jitter_bit;
    wire rnd_valid = jitter_valid;

    // ===================================================================
    // Section 2: Von Neumann Corrector (Debiasing Logic)
    // ===================================================================
    localparam S_WAIT_FIRST = 1'b0;
    localparam S_WAIT_SECOND = 1'b1;

    reg  state;
    reg  first_bit;
    wire debiased_bit;
    wire debiased_bit_valid;

    reg  out_bit_reg;
    reg  out_valid_reg;

    assign debiased_bit = out_bit_reg;
    assign debiased_bit_valid = out_valid_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            state         <= S_WAIT_FIRST;
            out_valid_reg <= 1'b0;
            first_bit     <= 1'b0;
            out_bit_reg   <= 1'b0;
        end else begin
            if (en) begin
                out_valid_reg <= 1'b0; // Default assignment

                // Only process when we have a new jitter sample
                if (rnd_valid) begin
                    if (state == S_WAIT_FIRST) begin
                        first_bit <= rnd_sync;
                        state     <= S_WAIT_SECOND;
                    end else begin // state == S_WAIT_SECOND
                        if (first_bit != rnd_sync) begin
                            out_bit_reg   <= first_bit;
                            out_valid_reg <= 1'b1;
                        end
                        state <= S_WAIT_FIRST;
                    end
                end
            end
        end
    end

    // ===================================================================
    // Section 3: XOR Accumulator (entropy amplification)
    // ===================================================================
    // XOR 8 debiased bits together to produce 1 output bit
    // This increases min-entropy per output bit
    reg [2:0] accum_count;
    reg       accum_bit;

    reg       accum_out_bit;
    reg       accum_out_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            accum_count     <= 3'd0;
            accum_bit       <= 1'b0;
            accum_out_bit   <= 1'b0;
            accum_out_valid <= 1'b0;
        end else begin
            if (en) begin
                accum_out_valid <= 1'b0; // Default assignment

                if (debiased_bit_valid) begin
                    accum_bit   <= accum_bit ^ debiased_bit;
                    accum_count <= accum_count + 1;

                    if (accum_count == 3'd7) begin
                        // Output the XOR of 8 debiased bits
                        accum_out_bit   <= accum_bit ^ debiased_bit;
                        accum_out_valid <= 1'b1;
                        accum_bit       <= 1'b0; // Reset for next accumulation
                    end
                end
            end
        end
    end

    // ===================================================================
    // Section 4: Data Collection
    // ===================================================================
    reg [4:0] bit_count;

    always @(posedge clk) begin
        if (!rst_n) begin
            rnd_out   <= 32'b0;
            bit_count <= 5'd0;
            ready     <= 1'b0;
        end else begin
            if (en) begin
                ready <= 1'b0; // Default assignment

                if (accum_out_valid) begin
                    rnd_out <= {rnd_out[30:0], accum_out_bit};
                    bit_count <= bit_count + 1;

                    if (bit_count == 5'd31) begin
                        ready     <= 1'b1;
                        bit_count <= 5'd0;
                    end
                end
            end
        end
    end

endmodule