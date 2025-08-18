// File: src/ring_osc_stub.v
// This is the stub for Yosys. It defines the I/O but has no logic.

module ring_osc (
    input  EN,  // Enable pin to control the oscillator
    output OUT  // The output that produces the random bitstream
);
    // Mark this module as a black box for the synthesis tool.
    (* blackbox *);

endmodule