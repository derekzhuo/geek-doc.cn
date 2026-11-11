module exported (
  input  wire clk,
  input  wire rst,
  input  wire start,
  input  wire finish,
  output wire ready,
  output wire done,
  output wire [1:0] debug_state
);
  localparam IDLE = 2'd0;
  localparam WORK = 2'd1;
  localparam DONE = 2'd2;

  reg [1:0] state;
  reg [1:0] next_state;

  always @(posedge clk) begin
    if (rst)
      state <= IDLE;
    else
      state <= next_state;
  end

  always @* begin
    next_state = state;
    case (state)
      IDLE:    if (start)  next_state = WORK;
      WORK:    if (finish) next_state = DONE;
      DONE:                next_state = IDLE;
      default:             next_state = IDLE;
    endcase
  end

  assign ready = (state == IDLE);
  assign done  = (state == DONE);
  assign debug_state = state;
endmodule
