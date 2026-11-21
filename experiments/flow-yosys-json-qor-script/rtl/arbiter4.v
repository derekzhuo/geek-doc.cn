module arbiter4 (
    input  wire [3:0] req,
    output wire [3:0] grant,
    output wire       valid
);
    assign valid  = |req;
    assign grant[0] = req[0];
    assign grant[1] = req[1] & ~req[0];
    assign grant[2] = req[2] & ~req[1] & ~req[0];
    assign grant[3] = req[3] & ~req[2] & ~req[1] & ~req[0];
endmodule
