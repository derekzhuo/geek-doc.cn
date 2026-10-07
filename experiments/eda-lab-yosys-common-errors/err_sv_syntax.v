// 错误 3：SystemVerilog 语法（logic / always_ff）直接 read_verilog
// 触发：未加 -sv 时 yosys 前端按 Verilog-2005 解析，报语法错
module sv_counter (
    input  logic clk,
    input  logic rst_n,
    output logic [3:0] cnt
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 4'd0;
        else        cnt <= cnt + 4'd1;
    end
endmodule
