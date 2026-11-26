module alu4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [3:0] result,
    output reg        n,
    output reg        z,
    output reg        c,
    output reg        v
);
    reg [4:0] ext;

    always @* begin
        result = 4'h0;
        ext = 5'h00;
        c = 1'b0;
        v = 1'b0;

        case (op)
            3'd0: begin
                ext = {1'b0, a} + {1'b0, b};
                result = ext[3:0];
                c = ext[4];
                v = (a[3] & b[3] & ~result[3]) |
                    (~a[3] & ~b[3] & result[3]);
            end
            3'd1: begin
                ext = {1'b0, a} + {1'b0, ~b} + 5'd1;
                result = ext[3:0];
`ifdef INJECT_SUB_CARRY
                c = ~ext[4];
`else
                c = ext[4];
`endif
                v = (a[3] & ~b[3] & ~result[3]) |
                    (~a[3] & b[3] & result[3]);
            end
            3'd2: result = a & b;
            3'd3: result = a | b;
            3'd4: result = a ^ b;
            default: result = 4'h0;
        endcase

        n = result[3];
        z = (result == 4'h0);
    end
endmodule
