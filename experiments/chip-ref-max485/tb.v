`timescale 1ns/1ps
module tb;
    reg di1 = 0, de1 = 0, re1_n = 1;
    reg di2 = 0, de2 = 0, re2_n = 1;
    wire ro1, ro2;
    wire a, b;
    integer errors = 0;

    max485 u1(.di(di1), .de(de1), .re_n(re1_n), .ro(ro1), .a(a), .b(b));
    max485 u2(.di(di2), .de(de2), .re_n(re2_n), .ro(ro2), .a(a), .b(b));

    task check_ro2;
        input expected;
        input [255:0] label;
        begin
            #1;
            if (ro2 !== expected) begin
                errors = errors + 1;
                $display("FAIL %0s ro2=%b expected=%b", label, ro2, expected);
            end else begin
                $display("PASS %0s ro2=%b", label, ro2);
            end
        end
    endtask

    initial begin
        de1 = 1; re2_n = 0; di1 = 1;
        check_ro2(1, "node1 drives one");
        di1 = 0;
        check_ro2(0, "node1 drives zero");

        #2 de1 = 0; re2_n = 1;
        #2 de2 = 1; re1_n = 0; di2 = 1;
        #1;
        if (ro1 !== 1) begin errors = errors + 1; $display("FAIL reverse direction ro1=%b", ro1); end
        else $display("PASS reverse direction after turnaround ro1=1");

        #2 de1 = 1; di1 = 0; re1_n = 1; re2_n = 1;
        #1;
        if (a !== 1'bx || b !== 1'bx) begin errors = errors + 1; $display("FAIL contention a=%b b=%b", a, b); end
        else $display("PASS opposing drivers produce contention X");

        #2 de1 = 0; de2 = 0;
        #1;
        if (a !== 1'bz || b !== 1'bz) begin errors = errors + 1; $display("FAIL idle bus a=%b b=%b", a, b); end
        else $display("PASS both drivers disabled release bus");

        $display("SUMMARY errors=%0d", errors);
        if (errors == 0) $display("PASS direction turnaround contention release");
        else $display("FAIL mismatches detected");
        $finish;
    end
endmodule
