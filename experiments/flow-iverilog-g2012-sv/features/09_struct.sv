// 09 packed struct: 可整体当向量操作的结构体
module t;
  typedef struct packed {
    logic [3:0] nibble;
    logic       flag;
    logic [2:0] tag;
  } pkt_t;
  pkt_t pkt;
  initial begin
    pkt = '{4'ha, 1'b1, 3'd3};
    #1 $display("PASS struct: nibble=%h flag=%0d tag=%0d raw=%b",
                pkt.nibble, pkt.flag, pkt.tag, pkt);
       $finish;
  end
endmodule
