module tb_task_count_bad;
    reg [7:0] a;
    reg [7:0] b;
    reg [8:0] sum;

    task add2;
        input [7:0] x;
        input [7:0] y;
        output reg [8:0] result;
        begin
            result = x + y;
        end
    endtask

    initial begin
        a = 8'd7;
        b = 8'd5;
        add2(a, b);
        $display("sum=%0d", sum);
        $finish;
    end
endmodule
