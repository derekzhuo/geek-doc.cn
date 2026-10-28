// 测试台：固定 a=1，翻转 b，观察两个版本的 y 是否跟随 {a,b} 更新
`timescale 1ns/1ns

module tb_decoder;

reg        a;
reg        b;
wire [3:0] y_bug;
wire [3:0] y_fix;
integer    err_bug;
integer    err_fix;

decoder_bug u_bug (.a(a), .b(b), .y(y_bug));
decoder_fix u_fix (.a(a), .b(b), .y(y_fix));

function [3:0] ref_y;
    input [1:0] s;
    case (s)
        2'b00: ref_y = 4'b0001;
        2'b01: ref_y = 4'b0010;
        2'b10: ref_y = 4'b0100;
        2'b11: ref_y = 4'b1000;
    endcase
endfunction

task check;
    begin
        #1;
        if (y_bug !== ref_y({a, b})) err_bug = err_bug + 1;
        if (y_fix !== ref_y({a, b})) err_fix = err_fix + 1;
        $display("t=%0t a=%b b=%b | bug y=%b %s | fix y=%b %s",
                 $time, a, b,
                 y_bug, (y_bug === ref_y({a, b})) ? "OK " : "STALE",
                 y_fix, (y_fix === ref_y({a, b})) ? "OK " : "WRONG");
    end
endtask

initial begin
    err_bug = 0;
    err_fix = 0;
    a = 0; b = 0; #10; check;   // 初值，两个版本都该正确
    a = 1;        #10; check;   // a 变化，敏感表含 a，两版都触发
    b = 1;        #10; check;   // b 变化：bug 版不触发，y 停留在旧值
    b = 0;        #10; check;   // b 再变：bug 版依旧不动
    a = 0;        #10; check;   // a 变化触发 bug 版，用新 b 重算，又“碰巧正确”

    $display("----");
    if (err_bug == 0) $display("BUG-VERSION  PASS (unexpected)");
    else              $display("BUG-VERSION  MISMATCH count=%0d", err_bug);
    if (err_fix == 0) $display("FIX-VERSION  PASS");
    else              $display("FIX-VERSION  FAIL count=%0d", err_fix);
    $finish;
end

endmodule
