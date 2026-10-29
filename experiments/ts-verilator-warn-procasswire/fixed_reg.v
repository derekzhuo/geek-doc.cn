module fixed_reg (
    input  wire a,
    output wire y
);
    reg q;

    always @* begin
        q = a;
    end

    assign y = q;
endmodule
