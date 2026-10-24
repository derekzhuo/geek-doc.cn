// LATCH: incomplete if in combinational block infers a latch
module latch_case (input wire en, input wire d, output reg q);
    always @(*) begin
        if (en) q = d;
    end
endmodule
