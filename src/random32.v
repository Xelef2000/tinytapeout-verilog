
`default_nettype none

`include "ring_osc_6.v"
`include "ring_osc_12.v"
`include "ring_osc_24.v"

module random32 (
    input  wire       clk,      // system clock
    input  wire       en,       // enable
    output reg [31:0] rnd_out,  // random 32-bit number
    output reg        ready,    // high for 1 cycle when rnd_out is fresh

    output wire       ring_out_6,
    output wire       ring_out_12,
    output wire       ring_out_24
);

    // ===================================================================
    // Section 1: Entropy Source
    // ===================================================================
    wire ring_bit_6, ring_bit_12, ring_bit_24;
    wire combined_ring_bit;
    reg  sync1, sync2;
    wire rnd_sync;

    ring_osc_6 u_ring6 (.en(en), .rnd(ring_bit_6));
    ring_osc_12 u_ring12 (.en(en), .rnd(ring_bit_12));
    ring_osc_24 u_ring24 (.en(en), .rnd(ring_bit_24));

    assign ring_out_6  = ring_bit_6;
    assign ring_out_12 = ring_bit_12;
    assign ring_out_24 = ring_bit_24;

    assign combined_ring_bit = ring_bit_6 ^ ring_bit_12 ^ ring_bit_24;

    always @(posedge clk) begin
        sync1 <= combined_ring_bit;
        sync2 <= sync1;
    end
    assign rnd_sync = sync2;

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
        if (!en) begin
            state <= S_WAIT_FIRST;
            out_valid_reg <= 1'b0;
        end else begin
            out_valid_reg <= 1'b0;
            
            if (state == S_WAIT_FIRST) begin
                first_bit <= rnd_sync;
                state     <= S_WAIT_SECOND;
            end else begin
                if (first_bit != rnd_sync) begin
                    out_bit_reg   <= first_bit;
                    out_valid_reg <= 1'b1;
                end
                state <= S_WAIT_FIRST;
            end
        end
    end

    // ===================================================================
    // Section 3: Data Collection (Modified to use debiased bits)
    // ===================================================================
    reg [4:0] bit_count;

    always @(posedge clk) begin
        if (!en) begin
            rnd_out   <= 32'b0;
            bit_count <= 5'd0;
            ready     <= 1'b0;
        end else begin
            ready <= 1'b0;
            
            if (debiased_bit_valid) begin
                rnd_out <= {rnd_out[30:0], debiased_bit};
                bit_count <= bit_count + 1;

                if (bit_count == 5'd31) begin
                    ready     <= 1'b1;
                    bit_count <= 5'd0;
                end
            end
        end
    end

endmodule