// 3-state Moore FSM: IDLE -> RUN -> DONE -> IDLE
module fsm3 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       go,
    input  wire       done,
    output reg  [1:0] led
);
    localparam [1:0] S_IDLE = 2'd0,
                     S_RUN  = 2'd1,
                     S_DONE = 2'd2;

    reg [1:0] state, next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next;
    end

    always @(*) begin
        next = state;
        case (state)
            S_IDLE: if (go)   next = S_RUN;
            S_RUN:  if (done) next = S_DONE;
            S_DONE:           next = S_IDLE;
            default:          next = S_IDLE;
        endcase
    end

    always @(*) begin
        case (state)
            S_IDLE: led = 2'b01;
            S_RUN:  led = 2'b10;
            S_DONE: led = 2'b11;
            default: led = 2'b00;
        endcase
    end
endmodule
