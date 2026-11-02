// 4 位可加载计数器：rst_n 异步复位，load 优先于 en
module counter #(
    parameter int WIDTH = 4
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    input  logic             load,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else if (load) begin
            q <= d;
        end else if (en) begin
            q <= q + 1'b1;
        end
    end
endmodule
