module blink (
    input  wire clk,
    input  wire rst_n,
    output wire led
);
    reg [23:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 24'd0;
        else
            counter <= counter + 24'd1;
    end

    assign led = counter[23];
endmodule
