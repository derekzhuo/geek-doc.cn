// 8 位可加载计数器：rst_n 异步复位，load 优先于 clear，clear 优先于 en，
// 计满 255 后自然回绕到 0。三个种子的激励都不驱动 clear，
// 用来制造一个合并后仍存在的真实覆盖缺口。
module counter #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    input  logic             load,
    input  logic             clear,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else if (load) begin
            q <= d;
        end else if (clear) begin
            q <= '0;
        end else if (en) begin
            q <= q + 1'b1;
        end
    end
endmodule
