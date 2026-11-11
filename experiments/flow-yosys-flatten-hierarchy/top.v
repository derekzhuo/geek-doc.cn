// 顶层：generate 例化 N 个 sub（sub 的 WIDTH 默认 4，与顶层 WIDTH 取同值）
module top #(
    parameter N     = 4,
    parameter WIDTH = 4
) (
    input                    clk,
    input                    rst_n,
    input      [N-1:0]       en,
    input      [N*WIDTH-1:0] d,
    output     [N*WIDTH-1:0] q
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g
            sub u_inst (
                .clk   (clk),
                .rst_n (rst_n),
                .en    (en[i]),
                .d     (d[i*WIDTH +: WIDTH]),
                .q     (q[i*WIDTH +: WIDTH])
            );
        end
    endgenerate
endmodule
