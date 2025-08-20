`default_nettype none

module ring_osc_12 (
    input  wire en, 
    output wire rnd 
);

`ifdef COCOTB_SIM
    assign rnd = en ? 1'b0 : 1'bz;

`elsif ECP5_FPGA
    wire n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, gated;

    (* keep, dont_touch, BEL="A6LUT", LOC="X0Y0" *)
    LUT4 #(.INIT(16'h7FFF)) u0 (
        .A(n11), 
        .B(en), 
        .C(1'b1), 
        .D(1'b1), 
        .Z(gated)
    );
    (* keep, dont_touch, BEL="B6LUT", LOC="X0Y0" *)
    LUT4 #(.INIT(16'h5555)) u1 (.A(gated), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n1));
    (* keep, dont_touch, BEL="C6LUT", LOC="X0Y0" *)
    LUT4 #(.INIT(16'h5555)) u2 (.A(n1),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n2));
    (* keep, dont_touch, BEL="D6LUT", LOC="X0Y0" *)
    LUT4 #(.INIT(16'h5555)) u3 (.A(n2),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n3));

    (* keep, dont_touch, BEL="A6LUT", LOC="X0Y1" *)
    LUT4 #(.INIT(16'h5555)) u4 (.A(n3),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n4));
    (* keep, dont_touch, BEL="B6LUT", LOC="X0Y1" *)
    LUT4 #(.INIT(16'h5555)) u5 (.A(n4),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n5));
    (* keep, dont_touch, BEL="C6LUT", LOC="X0Y1" *)
    LUT4 #(.INIT(16'h5555)) u6 (.A(n5),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n6));
    (* keep, dont_touch, BEL="D6LUT", LOC="X0Y1" *)
    LUT4 #(.INIT(16'h5555)) u7 (.A(n6),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n7));

    (* keep, dont_touch, BEL="A6LUT", LOC="X0Y2" *)
    LUT4 #(.INIT(16'h5555)) u8 (.A(n7),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n8));
    (* keep, dont_touch, BEL="B6LUT", LOC="X0Y2" *)
    LUT4 #(.INIT(16'h5555)) u9 (.A(n8),    .B(1'b0), .C(1'b0), .D(1'b0), .Z(n9));
    (* keep, dont_touch, BEL="C6LUT", LOC="X0Y2" *)
    LUT4 #(.INIT(16'h5555)) u10 (.A(n9),   .B(1'b0), .C(1'b0), .D(1'b0), .Z(n10));
    (* keep, dont_touch, BEL="D6LUT", LOC="X0Y2" *)
    LUT4 #(.INIT(16'h5555)) u11 (.A(n10),  .B(1'b0), .C(1'b0), .D(1'b0), .Z(n11));

    assign rnd = n11;

`else
    wire n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, gated;

    (* keep, dont_touch *) sg13g2_nand2_2 u0 (.Y(gated), .A(n11), .B(en));

    (* keep, dont_touch *) sg13g2_inv_2 u1 (.Y(n1), .A(gated));
    (* keep, dont_touch *) sg13g2_inv_2 u2 (.Y(n2), .A(n1));
    (* keep, dont_touch *) sg13g2_inv_2 u3 (.Y(n3), .A(n2));
    (* keep, dont_touch *) sg13g2_inv_2 u4 (.Y(n4), .A(n3));
    (* keep, dont_touch *) sg13g2_inv_2 u5 (.Y(n5), .A(n4));
    (* keep, dont_touch *) sg13g2_inv_2 u6 (.Y(n6), .A(n5));
    (* keep, dont_touch *) sg13g2_inv_2 u7 (.Y(n7), .A(n6));
    (* keep, dont_touch *) sg13g2_inv_2 u8 (.Y(n8), .A(n7));
    (* keep, dont_touch *) sg13g2_inv_2 u9 (.Y(n9), .A(n8));
    (* keep, dont_touch *) sg13g2_inv_2 u10 (.Y(n10), .A(n9));
    (* keep, dont_touch *) sg13g2_inv_2 u11 (.Y(n11), .A(n10));

    assign rnd = n11;
`endif

endmodule
