// top.v：8 位寄存器越界位选 [15:8]
module top;
    reg  [7:0] data;
    reg  [7:0] high_byte;

    initial begin
        data = 8'hA5;
        high_byte = data[15:8];   // 位选越界：声明只有 7:0
        $display("high_byte = %h", high_byte);
    end
endmodule
