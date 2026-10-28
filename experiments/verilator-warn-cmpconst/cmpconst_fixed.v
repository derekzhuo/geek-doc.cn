module cmpconst_fixed (
    input  wire clk,
    input  wire rst_n,
    output reg  done
);
    // 用「等于最大值」判断数满一圈，比较条件可达，done 正常拉起
    reg [7:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 8'd0;
            done <= 1'b0;
        end else begin
            cnt <= cnt + 8'd1;
            if (cnt == 8'd255)
                done <= 1'b1;
        end
    end
endmodule
