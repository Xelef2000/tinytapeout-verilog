module ring_osc_24 (
    input  wire en, 
    output wire rnd 
);

`ifdef COCOTB_SIM
    assign rnd = en ? 1'b0 : 1'bz;

`elsif ECP5_FPGA
    wire n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, gated;

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h7FFF)) u0 (.A(n23), .B(en), .C(1'b1), .D(1'b1), .Z(gated));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u1 (.A(gated), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n1));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u2 (.A(n1), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n2));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u3 (.A(n2), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n3));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u4 (.A(n3), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n4));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u5 (.A(n4), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n5));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u6 (.A(n5), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n6));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u7 (.A(n6), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n7));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u8 (.A(n7), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n8));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u9 (.A(n8), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n9));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u10 (.A(n9), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n10));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u11 (.A(n10), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n11));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u12 (.A(n11), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n12));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u13 (.A(n12), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n13));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u14 (.A(n13), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n14));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u15 (.A(n14), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n15));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u16 (.A(n15), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n16));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u17 (.A(n16), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n17));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u18 (.A(n17), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n18));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u19 (.A(n18), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n19));

    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u20 (.A(n19), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n20));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u21 (.A(n20), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n21));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u22 (.A(n21), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n22));
    (* keep, dont_touch *)
    LUT4 #(.INIT(16'h5555)) u23 (.A(n22), .B(1'b0), .C(1'b0), .D(1'b0), .Z(n23));

    assign rnd = n23;

`else
    wire n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, gated;

    (* keep, dont_touch *) sg13g2_nand2_2 u0 (.Y(gated), .A(n23), .B(en));

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
    (* keep, dont_touch *) sg13g2_inv_2 u12 (.Y(n12), .A(n11));
    (* keep, dont_touch *) sg13g2_inv_2 u13 (.Y(n13), .A(n12));
    (* keep, dont_touch *) sg13g2_inv_2 u14 (.Y(n14), .A(n13));
    (* keep, dont_touch *) sg13g2_inv_2 u15 (.Y(n15), .A(n14));
    (* keep, dont_touch *) sg13g2_inv_2 u16 (.Y(n16), .A(n15));
    (* keep, dont_touch *) sg13g2_inv_2 u17 (.Y(n17), .A(n16));
    (* keep, dont_touch *) sg13g2_inv_2 u18 (.Y(n18), .A(n17));
    (* keep, dont_touch *) sg13g2_inv_2 u19 (.Y(n19), .A(n18));
    (* keep, dont_touch *) sg13g2_inv_2 u20 (.Y(n20), .A(n19));
    (* keep, dont_touch *) sg13g2_inv_2 u21 (.Y(n21), .A(n20));
    (* keep, dont_touch *) sg13g2_inv_2 u22 (.Y(n22), .A(n21));
    (* keep, dont_touch *) sg13g2_inv_2 u23 (.Y(n23), .A(n22));

    assign rnd = n23;
`endif

endmodule