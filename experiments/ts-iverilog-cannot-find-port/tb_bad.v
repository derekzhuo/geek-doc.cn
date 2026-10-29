module tb_bad;
  reg clk;
  reg rst_n;
  reg enable;
  wire [3:0] count;

  counter dut (
      .clk    (clk),
      .rest_n (rst_n),
      .enable (enable),
      .count  (count)
  );
endmodule
