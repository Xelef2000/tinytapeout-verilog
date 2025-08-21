module clk_divider(
    input wire clk_in,      // 25MHz input clock
    input wire reset,       // Active high reset
    output reg clk_out      // 500kHz output clock
);

    // Calculate the division factor
    // 25MHz / 500kHz = 50
    // Need to toggle the output every 25 cycles
    
    // Counter to divide the clock
    reg [5:0] counter = 0;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == 24) begin
                counter <= 0;
                clk_out <= ~clk_out;  // Toggle the output clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
endmodule