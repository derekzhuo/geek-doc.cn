module blink (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led <= 1'b0;
        else
            led <= ~led;
    end
endmodule
