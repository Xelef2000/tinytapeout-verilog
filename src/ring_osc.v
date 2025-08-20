`default_nettype none

module ring_osc (
    input  wire en, 
    output wire rnd 
);
    wire n1, n2, n3, n4, n5, gated;

    (* keep, dont_touch *) sg13g2_nand2_2 u0 (.Y(gated), .A(n5), .B(en));

    (* keep, dont_touch *) sg13g2_inv_2 u1 (.Y(n1), .A(gated));
    (* keep, dont_touch *) sg13g2_inv_2 u2 (.Y(n2), .A(n1));
    (* keep, dont_touch *) sg13g2_inv_2 u3 (.Y(n3), .A(n2));
    (* keep, dont_touch *) sg13g2_inv_2 u4 (.Y(n4), .A(n3));
    (* keep, dont_touch *) sg13g2_inv_2 u5 (.Y(n5), .A(n4));

    assign rnd = n5;

endmodule
