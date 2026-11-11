`timescale 1ns/1ps

module tb;
    initial begin
        $timeformat(-9, 0, " ns", 10);
        $display("CASE fork-join");
        $display("%0t parent before fork", $time);
        fork
            begin
                #10;
                $display("%0t join short child done", $time);
            end
            begin
                #20;
                $display("%0t join long child done", $time);
            end
        join
        $display("%0t parent after join", $time);

        #30;
        $display("CASE fork-join_any");
        $display("%0t parent before fork", $time);
        fork
            begin
                #10;
                $display("%0t any short child done", $time);
            end
            begin
                #20;
                $display("%0t any long child done", $time);
            end
        join_any
        $display("%0t parent after join_any", $time);

        #30;
        $display("CASE fork-join_none");
        $display("%0t parent before fork", $time);
        fork
            begin
                $display("%0t none immediate child started", $time);
            end
            begin
                #10;
                $display("%0t none delayed child done", $time);
            end
        join_none
        $display("%0t parent after join_none", $time);

        #20;
        $display("CASE disable-fork");
        $display("%0t parent before fork", $time);
        fork
            begin
                #10;
                $display("%0t disable short child done", $time);
            end
            begin
                #30;
                $display("%0t ERROR long child survived", $time);
            end
        join_any
        $display("%0t parent after join_any", $time);
        disable fork;
        $display("%0t disable fork executed", $time);
        #40;
        $display("%0t parent after quiet wait", $time);

        #10;
        $display("CASE natural-exit");
        fork
            begin
                #20;
                $display("%0t detached child done", $time);
            end
        join_none
        $display("%0t parent initial block ends without finish", $time);
    end
endmodule
