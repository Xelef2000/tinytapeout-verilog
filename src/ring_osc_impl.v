// File: src/ring_osc_impl.v
// This is the actual implementation using IHP SG13G2 standard cells for OpenROAD.

module ring_osc (
    input  EN,
    output OUT
);

    // Internal wires connecting the inverter stages
    wire n1, n2, n3, n4;

    // Use a NAND gate for the first stage to allow enabling/disabling.
    // When EN is high, it acts as an inverter.
    // When EN is low, the output is forced high, breaking the oscillation.
    sg13g2_stdcell_nand2_1 u0 ( .A(EN), .B(n4), .Y(n1) );

    // Chain of inverters
    sg13g2_stdcell_inv_1 u1 ( .A(n1), .Y(n2) );
    sg13g2_stdcell_inv_1 u2 ( .A(n2), .Y(n3) );
    sg13g2_stdcell_inv_1 u3 ( .A(n3), .Y(n4) );

    // The last stage drives the module's output
    sg13g2_stdcell_inv_1 u4 ( .A(n4), .Y(OUT) );

endmodule