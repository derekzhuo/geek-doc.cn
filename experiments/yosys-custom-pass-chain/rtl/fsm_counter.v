module fsm_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [2:0] state_out,
    output reg  [7:0] count
);

localparam S_IDLE = 3'd0;
localparam S_RUN  = 3'd1;
localparam S_WAIT = 3'd2;
localparam S_DONE = 3'd3;

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        count <= 8'd0;
    end else begin
        case (state)
            S_IDLE: begin
                if (en)
                    state <= S_RUN;
            end
            S_RUN: begin
                count <= count + 8'd1;
                if (count == 8'd9)
                    state <= S_WAIT;
            end
            S_WAIT: begin
                state <= S_DONE;
            end
            S_DONE: begin
                state <= S_IDLE;
                count <= 8'd0;
            end
            default: begin
                state <= S_IDLE;
            end
        endcase
    end
end

always @(*) begin
    state_out = state;
end

endmodule
