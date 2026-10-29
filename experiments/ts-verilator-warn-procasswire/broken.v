module broken (
    input  wire a,
    output wire y
);
    wire q;

    always @* begin
        q = a;
    end

    assign y = q;
endmodule
