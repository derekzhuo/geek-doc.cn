module bad (
    input  wire a,
    output wire y
);
    wire [3:0] data;

    always @* begin
        data[3:1] = 3'b000;
        data[0]   = a;
    end

    assign y = data[0];
endmodule
