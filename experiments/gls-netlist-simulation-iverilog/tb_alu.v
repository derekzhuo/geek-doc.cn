// tb_alu.v — same testbench drives RTL and gate-level netlist; prints per-op results
`timescale 1ns/1ps
module tb_alu;
    reg  [7:0] a, b;
    reg  [1:0] op;
    wire [7:0] y;
    wire       zero;

`ifdef GLS
    simple_alu dut (.a(a), .b(b), .op(op), .y(y), .zero(zero));
`else
    simple_alu dut (.a(a), .b(b), .op(op), .y(y), .zero(zero));
`endif

    integer errors = 0;
    task check(input [7:0] ta, input [7:0] tb, input [1:0] top, input [7:0] exp);
        begin
            a = ta; b = tb; op = top; #10;
            if (y !== exp) begin
                $display("MISMATCH a=%h b=%h op=%0d y=%h exp=%h", ta, tb, top, y, exp);
                errors = errors + 1;
            end else
                $display("OK a=%h b=%h op=%0d y=%h zero=%b", ta, tb, top, y, zero);
        end
    endtask

    initial begin
        $display("=== tb_alu start ===");
        check(8'd10, 8'd5,  2'd0, 8'd15);   // add
        check(8'd10, 8'd5,  2'd1, 8'd5);    // sub
        check(8'hF0, 8'h3C, 2'd2, 8'h30);   // and
        check(8'hF0, 8'h3C, 2'd3, 8'hFC);   // or
        check(8'd0,  8'd0,  2'd0, 8'd0);    // zero flag path
        check(8'hFF, 8'h01, 2'd0, 8'h00);   // add wrap -> zero
        check(8'd7,  8'd7,  2'd1, 8'd0);    // sub equal -> zero
        check(8'h55, 8'hAA, 2'd2, 8'h00);   // and -> zero
        $display("=== tb_alu done, errors=%0d ===", errors);
        if (errors == 0) $display("TB_RESULT: PASS");
        else             $display("TB_RESULT: FAIL");
        $finish;
    end
endmodule
