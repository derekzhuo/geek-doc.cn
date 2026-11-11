module concurrent_assert (
    input wire clk,
    input wire valid,
    input wire ready
);
    assert property (valid == ready);
endmodule
