`default_nettype none
`include "uart_tx.v"
`include "random32.v"

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

    // -------------------------------------------------------------------------------- //
    // --- Integrated Logic from random_to_uart module ---
    // -------------------------------------------------------------------------------- //

    // Define local parameters based on the requirements
    parameter CLK_HZ = 500000;
    parameter BIT_RATE = 9600;

    // Internal signals
    wire uart_txd;               // UART transmit data line
    wire [31:0] random_number_w; // Wire to capture the random number
    wire        random_ready_w;  // Signal indicating a new random number is available
    wire        uart_busy_w;     // UART busy status
    
    // Registers for state and data
    reg         uart_tx_en_r;    // UART transmit enable register
    reg  [7:0]  uart_tx_data_r;  // UART transmit data register
    reg  [31:0] random_buffer_r; // Register to hold the 32-bit random number during transmission

    // Ring oscillator wires
    wire ring_out_6;
    wire ring_out_12;
    wire ring_out_24;
    
    random32 i_random (
        .clk(clk),
        .en(ena),
        .rst_n(rst_n),
        .rnd_out(random_number_w),
        .ready(random_ready_w),
        .ring_out_6(ring_out_6),
        .ring_out_12(ring_out_12),
        .ring_out_24(ring_out_24)
    );

    uart_tx #(
        .BIT_RATE(BIT_RATE),
        .CLK_HZ(CLK_HZ)
    ) i_uart_tx (
        .clk(clk),
        .resetn(rst_n),
        .uart_txd(uart_txd),
        .uart_tx_busy(uart_busy_w),
        .uart_tx_en(uart_tx_en_r),
        .uart_tx_data(uart_tx_data_r)
    );

    // State machine definitions
    localparam FSM_IDLE = 1'b0;
    localparam FSM_SEND = 1'b1;
    
    // State machine registers
    reg fsm_state_r;
    reg [1:0] byte_counter_r;

    reg fsm_state_next;
    reg [1:0] byte_counter_next;
    reg uart_tx_en_next;
    reg [7:0] uart_tx_data_next;
    reg [31:0] random_buffer_next;

    always @(*) begin
        fsm_state_next     = fsm_state_r;
        byte_counter_next  = byte_counter_r;
        uart_tx_en_next    = 1'b0; // Default to not sending
        uart_tx_data_next  = uart_tx_data_r;
        random_buffer_next = random_buffer_r;

        case (fsm_state_r)
            FSM_IDLE: begin
                // If a new random number is ready, latch it and prepare to send.
                if (random_ready_w) begin
                    random_buffer_next = random_number_w;
                    fsm_state_next     = FSM_SEND;
                    byte_counter_next  = 2'b00; // Reset byte counter
                end
            end

            FSM_SEND: begin
                // Only proceed if the UART module is not busy
                if (!uart_busy_w) begin
                    uart_tx_en_next = 1'b1; // Enable transmission
                    
                    // Select the correct byte to send based on the current counter value
                    case (byte_counter_r)
                        2'b00: uart_tx_data_next = random_buffer_r[7:0];
                        2'b01: uart_tx_data_next = random_buffer_r[15:8];
                        2'b10: uart_tx_data_next = random_buffer_r[23:16];
                        2'b11: uart_tx_data_next = random_buffer_r[31:24];
                    endcase

                    // After sending the last byte, return to IDLE. Otherwise, increment counter.
                    if (byte_counter_r == 2'b11) begin
                        fsm_state_next = FSM_IDLE;
                    end else begin
                        byte_counter_next = byte_counter_r + 1;
                    end
                end
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state_r     <= FSM_IDLE;
            byte_counter_r  <= 2'b00;
            uart_tx_en_r    <= 1'b0;
            uart_tx_data_r  <= 8'h00;
            random_buffer_r <= 32'h00000000;
        end else begin
            fsm_state_r     <= fsm_state_next;
            byte_counter_r  <= byte_counter_next;
            uart_tx_en_r    <= uart_tx_en_next;
            uart_tx_data_r  <= uart_tx_data_next;
            random_buffer_r <= random_buffer_next;
        end
    end

    // -------------------------------------------------------------------------------- //
    // --- Top-level port assignments ---
    // -------------------------------------------------------------------------------- //
    
    assign uo_out[0] = uart_txd;
    assign uo_out[1] = ring_out_6;
    assign uo_out[2] = ring_out_12;
    assign uo_out[3] = ring_out_24;

    // Tie off unused outputs
    assign uo_out[7:4] = 4'b0;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0; // Set all bidirectional IOs to be inputs
    wire _unused = &{uio_in, ui_in, 1'b0};




endmodule