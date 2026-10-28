// tb_alu8: 随机激励自校验 testbench，种子经 +seed=N 传入
`timescale 1ns/1ps
module tb_alu8;
    reg  [7:0] a, b;
    reg  [1:0] op;
    wire [7:0] y;
    integer seed, i, errors;
    reg [7:0] exp;

    alu8 dut (.a(a), .b(b), .op(op), .y(y));

    initial begin
        errors = 0;
        if (!$value$plusargs("seed=%d", seed)) seed = 1;
        // FAIL_INJECT 宏打开时人为让 seed=13 必挂，用于演示失败汇总
`ifdef FAIL_INJECT
        if (seed == 13) begin
            $display("TEST FAIL seed=%0d (injected failure)", seed);
            $finish;
        end
`endif
        for (i = 0; i < 50; i = i + 1) begin
            a  = $random(seed);
            b  = $random(seed);
            op = $random(seed);
            #1;
            case (op)
                2'd0: exp = a + b;
                2'd1: exp = a - b;
                2'd2: exp = a & b;
                default: exp = a | b;
            endcase
            if (y !== exp) begin
                errors = errors + 1;
                $display("MISMATCH seed=%0d a=%h b=%h op=%0d y=%h exp=%h",
                         seed, a, b, op, y, exp);
            end
        end
        if (errors == 0)
            $display("TEST PASS seed=%0d vectors=50 errors=0", seed);
        else
            $display("TEST FAIL seed=%0d errors=%0d", seed, errors);
        $finish;
    end
endmodule
