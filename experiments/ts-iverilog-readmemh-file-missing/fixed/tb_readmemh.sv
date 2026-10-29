`timescale 1ns/1ps

module tb_readmemh;
    reg [7:0] mem [0:3];

    initial begin
        $readmemh("data/pattern.hex", mem);
        #1;
        if (mem[0] === 8'h11 && mem[1] === 8'h22 &&
            mem[2] === 8'h33 && mem[3] === 8'h44) begin
            $display("PASS: memory initialized from hex file");
        end else begin
            $fatal(1, "FAIL: memory was not initialized: %h %h %h %h",
                   mem[0], mem[1], mem[2], mem[3]);
        end
        $finish;
    end
endmodule
