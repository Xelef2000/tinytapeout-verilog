
module pi(
	input                        clk_i,
	input                        rst_n,
	output                       digit_ready_o,
    output reg [7:0]             digit_o
);

    reg [7:0] out_char;

    reg [3:0] digit_index_d;
    reg [3:0] digit_index_q;

    reg [1:0] state_d;
    reg [1:0] state_q;


    localparam STATE_IDLE = 2'b00;
    localparam STATE_SEND_CHAR = 2'b01;
    localparam STATE_DELAY = 2'b10;



    always @(*) begin
        case (digit_index_q)
            0: out_char = "3";
            1: out_char = "1";
            2: out_char = "4";
            3: out_char = "1";
            4: out_char = "5";
            5: out_char = "9";
            6: out_char = "2";
            7: out_char = "6";
            8: out_char = "5";
            9: out_char = "3";
            10: out_char = "5";
            default: out_char = "?"; // Error case
        endcase
    end

    always @(posedge clk or negedge rst_n) begin


endmodule