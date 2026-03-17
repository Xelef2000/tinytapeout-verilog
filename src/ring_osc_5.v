`default_nettype none

module ring_osc_5 (
    input  wire en, 
    output wire rnd 
);

`ifdef COCOTB_SIM
    // Simulation stub – avoids infinite oscillation
    assign rnd = en ? 1'b0 : 1'bz;

`elsif ECP5_FPGA
    wire n1, n2, n3, n4, gated;

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h7FFF)) u0 (
        .A(n4), 
        .B(en), 
        .C(1'b1), 
        .D(1'b1), 
        .Z(gated)
    );

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u1 (.A(gated), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n1));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u2 (.A(n1),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n2));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u3 (.A(n2),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n3));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u4 (.A(n3),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n4));

    assign rnd = n4;

`else
    wire n1, n2, n3, n4, gated;

    (* keep, dont_touch *) sg13g2_nand2_2 u0 (.Y(gated), .A(n4), .B(en));

    (* keep, dont_touch *) sg13g2_inv_2 u1 (.Y(n1), .A(gated));
    (* keep, dont_touch *) sg13g2_inv_2 u2 (.Y(n2), .A(n1));
    (* keep, dont_touch *) sg13g2_inv_2 u3 (.Y(n3), .A(n2));
    (* keep, dont_touch *) sg13g2_inv_2 u4 (.Y(n4), .A(n3));

    assign rnd = n4;
`endif

endmodule
