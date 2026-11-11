// Procedural delay: requires Verilator timing support (--timing).
module delay_gate (
    input  wire a,
    output reg  y
);
    always #2 y = a;
endmodule
