// File: src/ring_osc_impl.v
// This is the actual implementation using IHP SG13G2 standard cells.

module ring_osc (
    input  EN,
    output OUT
);

    // Internal wires connecting the inverter stages
    wire n1, n2, n3, n4;

    // The (* keep, nomerge *) attribute tells the synthesis tool to leave
    // these specific instances alone and not optimize them away.

    // Use a NAND gate for the first stage to allow enabling/disabling.
    (* keep, nomerge *) sg13g2_stdcell_nand2_1 u0 ( .A(EN), .B(n4), .Y(n1) );

    // Chain of inverters
    (* keep, nomerge *) sg13g2_stdcell_inv_1 u1 ( .A(n1), .Y(n2) );
    (* keep, nomerge *) sg13g2_stdcell_inv_1 u2 ( .A(n2), .Y(n3) );
    (* keep, nomerge *) sg13g2_stdcell_inv_1 u3 ( .A(n3), .Y(n4) );
    (* keep, nomerge *) sg13g2_stdcell_inv_1 u4 ( .A(n4), .Y(OUT) );

endmodule