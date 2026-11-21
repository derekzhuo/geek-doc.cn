module accumulator (
    input  wire        clk,
    input  wire        load,
    input  wire        en,
    input  wire [1:0]  step,
    input  wire [11:0] initial_value,
    output reg  [11:0] count,
    output wire        at_max
);
    always @(posedge clk) begin
        if (load)
            count <= initial_value;
        else if (en)
            count <= count + step;
    end

    assign at_max = &count;
endmodule
