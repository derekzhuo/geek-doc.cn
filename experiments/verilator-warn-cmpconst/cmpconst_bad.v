module cmpconst_bad (
    input  wire clk,
    input  wire rst_n,
    output reg  done
);
    // 8 位自由运行计数器，意图是数满一圈后拉起 done
    reg [7:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 8'd0;
            done <= 1'b0;
        end else begin
            cnt <= cnt + 8'd1;
            if (cnt > 8'd255)   // cnt 最大就是 255，比较恒假，done 永远拉不起来
                done <= 1'b1;
        end
    end
endmodule
