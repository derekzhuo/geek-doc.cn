`timescale 1ns/1ps

module safe_fsm #(
    parameter STATE_WIDTH = 2
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    input  wire ack,
    output reg  busy,
    output reg  valid
);
    localparam [STATE_WIDTH-1:0] IDLE = 0;
    localparam [STATE_WIDTH-1:0] BUSY = 1;
    localparam [STATE_WIDTH-1:0] DONE = 2;

    reg [STATE_WIDTH-1:0] state;
    reg [STATE_WIDTH-1:0] next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        next_state = state;
        busy = 1'b0;
        valid = 1'b0;

        case (state)
            IDLE: begin
                if (start)
                    next_state = BUSY;
            end
            BUSY: begin
                busy = 1'b1;
                if (done)
                    next_state = DONE;
            end
            DONE: begin
                valid = 1'b1;
                if (ack)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
                busy = 1'b0;
                valid = 1'b0;
            end
        endcase
    end
endmodule
