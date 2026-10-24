// CASEINCOMPLETE: case without default, not all states covered
module case_case (input wire [1:0] sel, input wire a, output reg y);
    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = ~a;
        endcase
    end
endmodule
