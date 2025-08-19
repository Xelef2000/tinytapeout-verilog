/*
 * This file provides empty module definitions for the linter (Verilator).
 * It prevents "Cannot find file containing module" errors when we
 * instantiate standard cells directly in our RTL.
 *
 * Yosys (synthesis) will use the real cell definitions from the PDK library.
 */

`default_nettype none

module sg13g2_stdcell_nand2_1 (Y, A, B);
    output Y;
    input A, B;
endmodule

module sg13g2_stdcell_inv_1 (Y, A);
    output Y;
    input A;
endmodule