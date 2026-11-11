// 19 covergroup: 功能覆盖率组（探测是否支持）
module t;
  bit [2:0] sel;
  covergroup cg_sel;
    cp_sel: coverpoint sel;
  endgroup
  cg_sel cg;
  initial begin
    cg = new();
    sel = 3'd3;
    cg.sample();
    #1 $display("PASS covergroup: sampled");
       $finish;
  end
endmodule
