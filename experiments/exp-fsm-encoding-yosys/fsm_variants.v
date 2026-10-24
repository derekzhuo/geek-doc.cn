// Same 4-state FSM, encoding selected by the fsm_encoding attribute.
// Instantiate three times with different attributes; yosys fsm pass picks
// binary / one-hot / gray state assignment per attribute.
module fsm_bin (input wire clk, input wire rst_n, input wire go, output reg done);
    (* fsm_encoding = "binary" *)
    reg [1:0] state;
    localparam IDLE = 0, RUN = 1, WAIT = 2, DONE = 3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= IDLE; done <= 0; end
        else case (state)
            IDLE: begin done <= 0; if (go) state <= RUN; end
            RUN:  state <= WAIT;
            WAIT: if (!go) state <= DONE;
            DONE: begin done <= 1; state <= IDLE; end
            default: state <= IDLE;
        endcase
    end
endmodule

module fsm_onehot (input wire clk, input wire rst_n, input wire go, output reg done);
    (* fsm_encoding = "one-hot" *)
    reg [1:0] state;
    localparam IDLE = 0, RUN = 1, WAIT = 2, DONE = 3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= IDLE; done <= 0; end
        else case (state)
            IDLE: begin done <= 0; if (go) state <= RUN; end
            RUN:  state <= WAIT;
            WAIT: if (!go) state <= DONE;
            DONE: begin done <= 1; state <= IDLE; end
            default: state <= IDLE;
        endcase
    end
endmodule

module fsm_gray (input wire clk, input wire rst_n, input wire go, output reg done);
    (* fsm_encoding = "gray" *)
    reg [1:0] state;
    localparam IDLE = 0, RUN = 1, WAIT = 2, DONE = 3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= IDLE; done <= 0; end
        else case (state)
            IDLE: begin done <= 0; if (go) state <= RUN; end
            RUN:  state <= WAIT;
            WAIT: if (!go) state <= DONE;
            DONE: begin done <= 1; state <= IDLE; end
            default: state <= IDLE;
        endcase
    end
endmodule
