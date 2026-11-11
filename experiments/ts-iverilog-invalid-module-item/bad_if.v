module bad_if (
    input  wire a,
    output reg  y
);
    if (a) begin
        y = 1'b1;
    end
endmodule
