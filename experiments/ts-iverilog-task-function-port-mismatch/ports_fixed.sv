module tb_ports_fixed;
    reg [7:0] a;
    reg [7:0] b;
    reg [8:0] task_sum;
    reg [8:0] function_sum;

    task add2;
        input [7:0] x;
        input [7:0] y;
        output reg [8:0] result;
        begin
            result = x + y;
        end
    endtask

    function [8:0] add2_function;
        input [7:0] x;
        input [7:0] y;
        begin
            add2_function = x + y;
        end
    endfunction

    initial begin
        a = 8'd7;
        b = 8'd5;
        add2(a, b, task_sum);
        function_sum = add2_function(a, b);
        if (task_sum === 9'd12 && function_sum === 9'd12) begin
            $display("PASS: task_sum=%0d function_sum=%0d", task_sum, function_sum);
        end else begin
            $fatal(1, "FAIL: task_sum=%0d function_sum=%0d", task_sum, function_sum);
        end
        $finish;
    end
endmodule
