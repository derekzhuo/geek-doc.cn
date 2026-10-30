module bad_parenthesis (
    input  wire a,
    output reg  y
);
    always @* begin
        if (a begin
            y = 1'b1;
        end
    end
endmodule
