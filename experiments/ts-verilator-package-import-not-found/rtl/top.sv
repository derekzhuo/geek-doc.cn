module top;
  import iopkg::*;
  var op_t op = OP_ADD;
  logic [WIDTH-1:0] a = 8'd3, b = 8'd4, y;
  always @(*) begin
    case (op)
      OP_ADD: y = a + b;
      OP_SUB: y = a - b;
      OP_MUL: y = a * b;
      default: y = '0;
    endcase
  end
endmodule
