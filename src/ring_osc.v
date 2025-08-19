`default_nettype none


module ro_trng (
    output wire rnd
);
    wire n1, n2, n3, n4, n5;

     sg13g2_inv_2 u1 (.Y(n1), .A(n5));
     sg13g2_inv_2 u2 (.Y(n2), .A(n1));
     sg13g2_inv_2 u3 (.Y(n3), .A(n2));
     sg13g2_inv_2 u4 (.Y(n4), .A(n3));
     sg13g2_inv_2 u5 (.Y(n5), .A(n4));

    assign rnd = n5;

endmodule


`ifndef SYNTHESIS
module ro_trng (
    output reg rnd
);
    initial rnd = 0;
    always #5 rnd = ~rnd;  
endmodule
`endif
