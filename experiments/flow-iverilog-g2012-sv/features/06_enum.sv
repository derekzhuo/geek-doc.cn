// 06 enum: 具名枚举状态
module t;
  typedef enum logic [1:0] {IDLE, BUSY, DONE} state_t;
  state_t st;
  initial begin
    st = BUSY;
    #1 $display("PASS enum: st=%s value=%0d", st.name(), st);
       $finish;
  end
endmodule
