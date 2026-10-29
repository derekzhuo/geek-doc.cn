`include "local.svh"
`include "config.svh"

module tb_include;
    initial begin
        if (`LOCAL_VALUE === 8'h2a && `CFG_WIDTH == 6) begin
            $display("PASS: LOCAL_VALUE=%0d CFG_WIDTH=%0d",
                     `LOCAL_VALUE, `CFG_WIDTH);
        end else begin
            $fatal(1, "FAIL: include values are incorrect");
        end
        $finish;
    end
endmodule
