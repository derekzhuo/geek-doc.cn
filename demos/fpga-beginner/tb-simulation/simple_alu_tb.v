`timescale 1ns/1ps
// simple_alu_tb.v —— 组合逻辑的「自检测试台」（不可综合，仅仿真）
// 配套 fpga/beginner/04-testbench-simulation.md。
// 演示 testbench 三件套：task 封装检查、定向用例 + 随机用例、参考模型(expected)自动比对并计数错误。
// 跑法：iverilog -o alu_sim simple_alu.v simple_alu_tb.v && vvp alu_sim
module simple_alu_tb;
    reg  [7:0] a, b;
    reg  [1:0] op;
    wire [7:0] y;
    wire       z, carry;

    integer tests  = 0;
    integer errors = 0;
    integer i;
    reg [7:0] exp_y;
    reg       exp_carry;

    // 被测对象(DUT)
    simple_alu dut (
        .a(a), .b(b), .op(op),
        .y(y), .z(z), .carry(carry)
    );

    // 组合逻辑：给完激励等一个小延迟(#1)让输出稳定，再按期望值自检
    task check;
        input [7:0] ia, ib;
        input [1:0] iop;
        input [7:0] ey;
        input       ec;
        begin
            a = ia; b = ib; op = iop;
            #1;
            tests = tests + 1;
            if (y !== ey || carry !== ec) begin
                errors = errors + 1;
                $display("  [FAIL] a=%h b=%h op=%b -> y=%h z=%b carry=%b | expect y=%h carry=%b",
                          ia, ib, iop, y, z, carry, ey, ec);
            end
        end
    endtask

    initial begin
        $dumpfile("simple_alu_tb.vcd");
        $dumpvars(0, simple_alu_tb);

        // ---- 1) 定向用例：人手算好的边界/典型情况 ----
        $display("== directed tests ==");
        check(8'hF0, 8'h0F, 2'b00, 8'h00, 1'b0); // AND: F0&0F=00 (z 应=1)
        check(8'hF0, 8'h0F, 2'b01, 8'hFF, 1'b0); // OR : F0|0F=FF
        check(8'h05, 8'h03, 2'b10, 8'h08, 1'b0); // ADD: 5+3=8
        check(8'hFF, 8'h01, 2'b10, 8'h00, 1'b1); // ADD: FF+1=100 -> y=00,carry=1
        check(8'h05, 8'h03, 2'b11, 8'h02, 1'b0); // SUB: 5-3=2, 无借位
        check(8'h03, 8'h05, 2'b11, 8'hFE, 1'b1); // SUB: 3-5 -> y=FE, 借位 carry=1

        // ---- 2) 随机用例：在 testbench 里建一个「参考模型」自动算期望值 ----
        $display("== random tests ==");
        for (i = 0; i < 300; i = i + 1) begin
            a  = $random & 8'hFF;
            b  = $random & 8'hFF;
            op = $random & 2'b11;
            #1;
            tests = tests + 1;
            // 参考模型：和 RTL 同样的运算规则，独立写一遍
            case (op)
                2'b00: begin exp_y = a & b;  exp_carry = 1'b0;        end
                2'b01: begin exp_y = a | b;  exp_carry = 1'b0;        end
                2'b10: begin {exp_carry, exp_y} = a + b; end // 9 位拼接捕获进位
                2'b11: begin {exp_carry, exp_y} = a - b; end // 借位落在 bit[8]
            endcase
            if (y !== exp_y || carry !== exp_carry || z !== (exp_y === 8'h00)) begin
                errors = errors + 1;
                $display("  [FAIL] rand a=%h b=%h op=%b -> y=%h z=%b c=%b | expect y=%h c=%b",
                          a, b, op, y, z, carry, exp_y, exp_carry);
            end
        end

        $display("---------------------------------------");
        $display("TESTS=%0d  ERRORS=%0d", tests, errors);
        if (errors == 0)
            $display("ALU SELF-CHECK *** PASSED ***");
        else
            $display("ALU SELF-CHECK *** FAILED ***");
        $finish;
    end
endmodule
