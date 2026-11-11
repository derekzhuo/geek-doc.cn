// 16 dynamic array: 运行时定长的动态数组（探测是否支持）
module t;
  int arr[];
  initial begin
    arr = new[4];
    foreach (arr[i]) arr[i] = i * i;
    #1 $display("PASS dynamic array: size=%0d last=%0d", arr.size(), arr[3]);
       $finish;
  end
endmodule
