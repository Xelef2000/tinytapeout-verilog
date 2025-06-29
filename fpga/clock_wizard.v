module clock_wizard (
    input  wire clk_in,     // 27 MHz input clock
    input  wire reset_n,    // Active low reset
    output reg  clk_out,    // 500 kHz output clock
    output wire locked      // Always locked for counter-based divider
);

    // Clock division calculation:
    // 27 MHz / 500 kHz = 54
    // So we need to divide by 54
    // For 50% duty cycle, toggle every 27 cycles
    localparam DIVIDE_VALUE = 27; // Toggle every 27 cycles for 54 total
    localparam COUNTER_WIDTH = 6; // log2(27) + 1 = 6 bits needed
    
    reg [COUNTER_WIDTH-1:0] counter;
    reg divider_locked;
    
    // Input clock buffer
    wire clk_bufg;
    IBUF clk_ibuf_inst (
        .I(clk_in),
        .O(clk_bufg)
    );
    
    // Counter-based clock divider
    always @(posedge clk_bufg or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
            divider_locked <= 1'b0;
        end else begin
            if (counter == DIVIDE_VALUE - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;    // Toggle output clock
                divider_locked <= 1'b1; // Mark as locked after first cycle
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
    // Output the lock status (always locked for counter divider)
    assign locked = divider_locked;

endmodule