module top_use_adder;
    reg  [7:0] a = 8'd15;
    reg  [7:0] b = 8'd27;
    wire [8:0] sum;

    sub_adder u_adder (
        .a   (a),
        .b   (b),
        .sum (sum)
    );

    initial begin
        #1;
        $display("sum=%0d", sum);
        $finish;
    end
endmodule
