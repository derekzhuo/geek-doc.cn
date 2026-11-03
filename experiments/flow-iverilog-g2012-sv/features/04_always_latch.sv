// 04 always_latch: 锁存推断块
module t;
  logic en;
  logic [7:0] d, q;
  always_latch begin
    if (en) q = d;
  end
  initial begin
    en = 1; d = 8'h3c;
    #1 en = 0; d = 8'hff;
    #1 $display("PASS always_latch: q=0x%0h (expect 3c)", q);
        $finish;
  end
endmodule
