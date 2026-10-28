// top_fixed.v：声明扩到 16 位，位选 [15:8] 合法
module top_fixed;
    reg  [15:0] data;
    reg  [7:0]  high_byte;

    initial begin
        data = 16'hA53C;
        high_byte = data[15:8];
        if (high_byte === 8'hA5)
            $display("PASS: high_byte = %h", high_byte);
        else
            $display("FAIL: high_byte = %h", high_byte);
    end
endmodule
