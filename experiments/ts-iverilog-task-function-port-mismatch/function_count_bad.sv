module tb_function_count_bad;
    reg [7:0] a;
    reg [7:0] b;
    reg [8:0] sum;

    function [8:0] add2;
        input [7:0] x;
        input [7:0] y;
        begin
            add2 = x + y;
        end
    endfunction

    initial begin
        a = 8'd7;
        b = 8'd5;
        sum = add2(a);
        $display("sum=%0d", sum);
        $finish;
    end
endmodule
