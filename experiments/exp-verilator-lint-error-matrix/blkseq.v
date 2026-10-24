// BLKSEQ: blocking assignment inside a clocked always block
module blkseq_case (input wire clk, input wire d, output reg q);
    always @(posedge clk) begin
        q = d;   // should be <=
    end
endmodule
