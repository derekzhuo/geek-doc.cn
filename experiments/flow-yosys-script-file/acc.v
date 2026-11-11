module acc #(
    parameter W = 4
) (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    input  wire [W-1:0]  din,
    output reg  [W-1:0]  q,
    output wire          carry
);
    wire [W-1:0] next;

    adder #(.W(W)) u_add (
        .a(q), .b(din), .y(next)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {W{1'b0}};
        else if (en)
            q <= next;
    end

    assign carry = &q;
endmodule
