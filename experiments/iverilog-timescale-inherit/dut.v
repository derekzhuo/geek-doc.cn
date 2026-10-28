// dut.v —— 故意不写 `timescale：#2 延时的实际单位取决于继承到的时间单位
module dut(input wire clk, input wire en, output reg y = 0);
  reg en_d = 0;
  // 意图：打一拍再输出，#2 只是建模仿真的小延时
  always @(posedge clk) begin
    en_d <= #2 en;
    y    <= #2 en_d;
  end
endmodule
