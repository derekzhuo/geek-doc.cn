module top_gp (
  input  wire clk,
  input  wire in,
  output wire out
);
  wire [48:0] chain ;
  assign chain[0] = in ;
  BUF_X1 u_buf0 (.A(chain[0]), .Y(chain[1])) ;
  BUF_X1 u_buf1 (.A(chain[1]), .Y(chain[2])) ;
  BUF_X1 u_buf2 (.A(chain[2]), .Y(chain[3])) ;
  BUF_X1 u_buf3 (.A(chain[3]), .Y(chain[4])) ;
  BUF_X1 u_buf4 (.A(chain[4]), .Y(chain[5])) ;
  BUF_X1 u_buf5 (.A(chain[5]), .Y(chain[6])) ;
  BUF_X1 u_buf6 (.A(chain[6]), .Y(chain[7])) ;
  BUF_X1 u_buf7 (.A(chain[7]), .Y(chain[8])) ;
  BUF_X1 u_buf8 (.A(chain[8]), .Y(chain[9])) ;
  BUF_X1 u_buf9 (.A(chain[9]), .Y(chain[10])) ;
  BUF_X1 u_buf10 (.A(chain[10]), .Y(chain[11])) ;
  BUF_X1 u_buf11 (.A(chain[11]), .Y(chain[12])) ;
  BUF_X1 u_buf12 (.A(chain[12]), .Y(chain[13])) ;
  BUF_X1 u_buf13 (.A(chain[13]), .Y(chain[14])) ;
  BUF_X1 u_buf14 (.A(chain[14]), .Y(chain[15])) ;
  BUF_X1 u_buf15 (.A(chain[15]), .Y(chain[16])) ;
  BUF_X1 u_buf16 (.A(chain[16]), .Y(chain[17])) ;
  BUF_X1 u_buf17 (.A(chain[17]), .Y(chain[18])) ;
  BUF_X1 u_buf18 (.A(chain[18]), .Y(chain[19])) ;
  BUF_X1 u_buf19 (.A(chain[19]), .Y(chain[20])) ;
  BUF_X1 u_buf20 (.A(chain[20]), .Y(chain[21])) ;
  BUF_X1 u_buf21 (.A(chain[21]), .Y(chain[22])) ;
  BUF_X1 u_buf22 (.A(chain[22]), .Y(chain[23])) ;
  BUF_X1 u_buf23 (.A(chain[23]), .Y(chain[24])) ;
  BUF_X1 u_buf24 (.A(chain[24]), .Y(chain[25])) ;
  BUF_X1 u_buf25 (.A(chain[25]), .Y(chain[26])) ;
  BUF_X1 u_buf26 (.A(chain[26]), .Y(chain[27])) ;
  BUF_X1 u_buf27 (.A(chain[27]), .Y(chain[28])) ;
  BUF_X1 u_buf28 (.A(chain[28]), .Y(chain[29])) ;
  BUF_X1 u_buf29 (.A(chain[29]), .Y(chain[30])) ;
  BUF_X1 u_buf30 (.A(chain[30]), .Y(chain[31])) ;
  BUF_X1 u_buf31 (.A(chain[31]), .Y(chain[32])) ;
  BUF_X1 u_buf32 (.A(chain[32]), .Y(chain[33])) ;
  BUF_X1 u_buf33 (.A(chain[33]), .Y(chain[34])) ;
  BUF_X1 u_buf34 (.A(chain[34]), .Y(chain[35])) ;
  BUF_X1 u_buf35 (.A(chain[35]), .Y(chain[36])) ;
  BUF_X1 u_buf36 (.A(chain[36]), .Y(chain[37])) ;
  BUF_X1 u_buf37 (.A(chain[37]), .Y(chain[38])) ;
  BUF_X1 u_buf38 (.A(chain[38]), .Y(chain[39])) ;
  BUF_X1 u_buf39 (.A(chain[39]), .Y(chain[40])) ;
  BUF_X1 u_buf40 (.A(chain[40]), .Y(chain[41])) ;
  BUF_X1 u_buf41 (.A(chain[41]), .Y(chain[42])) ;
  BUF_X1 u_buf42 (.A(chain[42]), .Y(chain[43])) ;
  BUF_X1 u_buf43 (.A(chain[43]), .Y(chain[44])) ;
  BUF_X1 u_buf44 (.A(chain[44]), .Y(chain[45])) ;
  BUF_X1 u_buf45 (.A(chain[45]), .Y(chain[46])) ;
  BUF_X1 u_buf46 (.A(chain[46]), .Y(chain[47])) ;
  BUF_X1 u_buf47 (.A(chain[47]), .Y(chain[48])) ;
  assign out = chain[48] ;
  SRAM64 u_sram0 (.clk(clk), .addr(in), .dout(chain[0])) ;
  SRAM40 u_sram1 (.clk(clk), .din(chain[48])) ;
endmodule
