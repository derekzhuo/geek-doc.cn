`timescale 1ns/1ps
// datapath 自检 testbench：写两个寄存器，再验证加法和按位与
module tb_top;
    reg        clk = 0;
    reg  [1:0] op, raddr, waddr;
    reg  [7:0] imm;
    reg        we;
    wire [7:0] result;

    integer errors = 0;

    always #5 clk = ~clk;

    datapath u_dut (
        .clk(clk), .op(op), .raddr(raddr), .imm(imm),
        .we(we), .waddr(waddr), .result(result)
    );

    task check(input [8*16-1:0] name, input [7:0] got, input [7:0] exp);
    begin
        if (got !== exp) begin
            $display("[tb] FAIL  %0s: got=%0d exp=%0d", name, got, exp);
            errors = errors + 1;
        end else begin
            $display("[tb] ok    %0s: %0d", name, got);
        end
    end
    endtask

    initial begin
        // r0 恒为 0；op=OR(11) 时 result = r0 | imm = imm，借道把立即数写进寄存器
        @(negedge clk);
        we = 1; waddr = 2'd1; raddr = 2'd0; op = 2'b11; imm = 8'd10;
        @(negedge clk);
        waddr = 2'd2; imm = 8'd3;
        @(negedge clk);

        // 读 r1=10，与 imm=3 运算：10+3=13，10&3=2
        we = 0; raddr = 2'd1; op = 2'b00; imm = 8'd3;
        #1 check("add", result, 8'd13);
        op = 2'b10;
        #1 check("and", result, 8'd2);

        if (errors == 0) $display("[tb] PASS");
        else             $display("[tb] FAIL errors=%0d", errors);
        $finish;
    end
endmodule
