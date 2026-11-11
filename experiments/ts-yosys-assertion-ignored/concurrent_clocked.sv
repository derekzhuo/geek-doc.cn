module concurrent_clocked (
    input wire clk,
    input wire valid,
    input wire ready
);
    assert property (@(posedge clk) valid |-> ready);
endmodule
