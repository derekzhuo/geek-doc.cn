// Counter + seven-segment decoder: one-day quickstart demo module.
module seg7_demo (
    input  wire       clk,
    input  wire       rst_n,
    output wire [6:0] seg
);
    reg [3:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 4'd0;
        else        cnt <= cnt + 4'd1;
    end

    // active-low segments {g,f,e,d,c,b,a} for hex digit
    reg [6:0] lut;
    always @(*) begin
        case (cnt)
            4'h0: lut = 7'b1000000;
            4'h1: lut = 7'b1111001;
            4'h2: lut = 7'b0100100;
            4'h3: lut = 7'b0110000;
            4'h4: lut = 7'b0011001;
            4'h5: lut = 7'b0010010;
            4'h6: lut = 7'b0000010;
            4'h7: lut = 7'b1111000;
            4'h8: lut = 7'b0000000;
            4'h9: lut = 7'b0010000;
            4'hA: lut = 7'b0001000;
            4'hB: lut = 7'b0000011;
            4'hC: lut = 7'b1000110;
            4'hD: lut = 7'b0100001;
            4'hE: lut = 7'b0000110;
            default: lut = 7'b0001110; // F
        endcase
    end
    assign seg = lut;
endmodule
