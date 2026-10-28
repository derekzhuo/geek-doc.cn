// 反例：case 分支取值重叠，第二个 4'b0011 永远不可达
module decoder_bad (
    input  wire [3:0] sel,
    output reg  [7:0] out
);
    always @(*) begin
        case (sel)
            4'b0000: out = 8'h00;
            4'b0001: out = 8'h11;
            4'b0011: out = 8'h33;   // 第一次覆盖 0011
            4'b0111: out = 8'h77;
            4'b0011: out = 8'hFF;   // 重叠：死代码，Verilator 报 CASEOVERLAP
            default: out = 8'hAA;
        endcase
    end
endmodule
