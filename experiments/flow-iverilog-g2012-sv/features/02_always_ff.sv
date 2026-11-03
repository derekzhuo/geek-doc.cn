// 02 always_ff: 时钟沿触发器
module t;
  logic clk = 0;
  logic rst_n = 0;
  logic [3:0] q = 0;
  always #5 clk = ~clk;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 4'd0;
    else        q <= q + 4'd1;
  end
  initial begin
    #2  rst_n = 1;
    #50 $display("PASS always_ff: q=%0d (expect 5)", q);
         $finish;
  end
endmodule
