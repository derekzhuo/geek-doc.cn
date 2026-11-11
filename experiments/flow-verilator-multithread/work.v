// 参数化大设计：N 个互相独立的工作单元，给 --threads 提供可并行切分的评估任务
`default_nettype none
`ifndef WORKN
 `define WORKN 4096
`endif

module worker (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] seed,
    output reg  [31:0] sum
);
    reg [31:0] lfsr;
    wire feedback = lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0];
    wire [31:0] mixed  = lfsr ^ {lfsr[15:0], lfsr[31:16]};
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= seed;
            sum  <= 32'd0;
        end else if (en) begin
            lfsr <= {lfsr[30:0], feedback};
            sum  <= sum + mixed + (lfsr & 32'h9E3779B9);
        end
    end
endmodule

module worktree #(
    parameter integer N = `WORKN
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    output wire [31:0] checksum
);
    wire [31:0] sums [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_workers
            worker u_worker (
                .clk(clk), .rst_n(rst_n), .en(en),
                .seed(32'h12345678 ^ (i * 32'h01000193)),
                .sum(sums[i])
            );
        end
    endgenerate

    // 异或归约树：跨单元的唯一连接，且只是旁路校验
    reg [31:0] xor_all;
    integer k;
    always @(*) begin
        xor_all = 32'd0;
        for (k = 0; k < N; k = k + 1)
            xor_all = xor_all ^ sums[k];
    end
    assign checksum = xor_all;
endmodule
