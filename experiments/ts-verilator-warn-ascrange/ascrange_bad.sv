module ascrange_bad (
    input  wire [0:3] data_i,
    output wire [3:0] reversed_o
);
    assign reversed_o = {data_i[0], data_i[1], data_i[2], data_i[3]};
endmodule
