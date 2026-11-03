// 17 queue: [$] 队列类型（探测是否支持）
module t;
  int q[$];
  initial begin
    q.push_back(10);
    q.push_back(20);
    q.push_front(5);
    #1 $display("PASS queue: size=%0d first=%0d last=%0d", q.size(), q[0], q[$]);
       $finish;
  end
endmodule
