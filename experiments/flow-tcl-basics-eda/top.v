// Hand-written gate-level netlist for the first STA run.
// In a real flow this file is the post-synthesis netlist written by Yosys
// (write_verilog after abc mapping to a standard-cell library).
module top (
    input  wire clk,
    input  wire d,
    input  wire en,
    output wire q
);
    wire s1, n1, s2;
    DFF_P     u_a (.D(d),  .C(clk), .Q(s1));
    NAND2_X1  g1  (.A(s1), .B(en), .Y(n1));
    BUF_X1    g2  (.A(n1),          .Y(s2));
    DFF_P     u_b (.D(s2), .C(clk), .Q(q));
endmodule
