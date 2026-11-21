module top (
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] led
);
    reg [23:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 24'd0;
        else
            count <= count + 24'd1;
    end

    assign led = count[23:20];
endmodule
