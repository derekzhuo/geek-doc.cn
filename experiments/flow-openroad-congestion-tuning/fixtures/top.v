module top(
  input  [31:0] in,
  output [31:0] out
);
  BUF_X1 b00(.A(in[ 0]), .Y(out[17]));
  BUF_X1 b01(.A(in[ 1]), .Y(out[ 3]));
  BUF_X1 b02(.A(in[ 2]), .Y(out[28]));
  BUF_X1 b03(.A(in[ 3]), .Y(out[10]));
  BUF_X1 b04(.A(in[ 4]), .Y(out[25]));
  BUF_X1 b05(.A(in[ 5]), .Y(out[ 6]));
  BUF_X1 b06(.A(in[ 6]), .Y(out[31]));
  BUF_X1 b07(.A(in[ 7]), .Y(out[13]));
  BUF_X1 b08(.A(in[ 8]), .Y(out[21]));
  BUF_X1 b09(.A(in[ 9]), .Y(out[ 1]));
  BUF_X1 b10(.A(in[10]), .Y(out[27]));
  BUF_X1 b11(.A(in[11]), .Y(out[ 8]));
  BUF_X1 b12(.A(in[12]), .Y(out[30]));
  BUF_X1 b13(.A(in[13]), .Y(out[15]));
  BUF_X1 b14(.A(in[14]), .Y(out[19]));
  BUF_X1 b15(.A(in[15]), .Y(out[ 4]));
  BUF_X1 b16(.A(in[16]), .Y(out[24]));
  BUF_X1 b17(.A(in[17]), .Y(out[11]));
  BUF_X1 b18(.A(in[18]), .Y(out[29]));
  BUF_X1 b19(.A(in[19]), .Y(out[ 2]));
  BUF_X1 b20(.A(in[20]), .Y(out[22]));
  BUF_X1 b21(.A(in[21]), .Y(out[ 7]));
  BUF_X1 b22(.A(in[22]), .Y(out[26]));
  BUF_X1 b23(.A(in[23]), .Y(out[14]));
  BUF_X1 b24(.A(in[24]), .Y(out[20]));
  BUF_X1 b25(.A(in[25]), .Y(out[ 0]));
  BUF_X1 b26(.A(in[26]), .Y(out[23]));
  BUF_X1 b27(.A(in[27]), .Y(out[ 9]));
  BUF_X1 b28(.A(in[28]), .Y(out[16]));
  BUF_X1 b29(.A(in[29]), .Y(out[ 5]));
  BUF_X1 b30(.A(in[30]), .Y(out[18]));
  BUF_X1 b31(.A(in[31]), .Y(out[12]));
endmodule
