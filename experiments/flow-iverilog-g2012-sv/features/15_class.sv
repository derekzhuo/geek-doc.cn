// 15 class: 面向对象类（探测是否支持）
class Packet;
  int id;
  function new(input int i);
    id = i;
  endfunction
  function int get();
    return id;
  endfunction
endclass

module t;
  Packet p;
  initial begin
    p = new(7);
    #1 $display("PASS class: id=%0d", p.get());
       $finish;
  end
endmodule
