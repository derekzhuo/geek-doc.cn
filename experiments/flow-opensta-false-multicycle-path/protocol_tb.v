`timescale 1ns/1ps
module protocol_tb;
  reg clk = 1'b0;
  reg d = 1'b0;
  reg cfg_in = 1'b0;
  reg run_en = 1'b0;
  wire data_q;
  wire shadow_q;
  reg expected;

  top dut (
    .clk(clk),
    .d(d),
    .cfg_in(cfg_in),
    .run_en(run_en),
    .data_q(data_q),
    .shadow_q(shadow_q)
  );

  always #5 clk = ~clk;

  task check(input condition, input [8*64-1:0] message);
    begin
      if (!condition) begin
        $display("PROTOCOL FAIL: %0s", message);
        $fatal(1);
      end
    end
  endtask

  initial begin
    // 维护窗口：功能寄存器保持，配置时钟继续运行。
    @(negedge clk);
    cfg_in = 1'b1;
    d = 1'b1;
    @(posedge clk); #1;
    @(posedge clk); #1;
    check(shadow_q === 1'b0, "configuration did not settle while run_en=0");
    check(dut.a === 1'b0 && data_q === 1'b0, "functional registers changed in maintenance");
    $display("PROTOCOL PASS: maintenance updates config, functional registers hold");

    // 恢复功能采样。phase=0 的下一个上升沿启动，隔一个上升沿捕获。
    @(negedge clk);
    run_en = 1'b1;
    d = 1'b1;
    @(posedge clk); #1;
    check(dut.a === 1'b1, "launch edge did not update u_a");
    check(data_q === 1'b0, "launch edge unexpectedly updated u_b");
    $display("PROTOCOL PASS: launch at active phase");

    expected = dut.n2;
    @(posedge clk); #1;
    check(dut.a === 1'b1 && data_q === 1'b0, "intermediate edge overwrote held data");
    $display("PROTOCOL PASS: intermediate edge holds launch and capture registers");

    @(posedge clk); #1;
    check(data_q === expected, "two-cycle capture data mismatch");
    $display("PROTOCOL PASS: capture after two functional cycles");

    // 再次进入维护窗口，改变输入也不能影响功能状态；配置可继续更新。
    @(negedge clk);
    run_en = 1'b0;
    d = 1'b0;
    cfg_in = 1'b0;
    expected = data_q;
    @(posedge clk); #1;
    @(posedge clk); #1;
    check(data_q === expected, "maintenance changed captured data");
    check(shadow_q === 1'b1, "configuration clock stopped in maintenance");
    $display("PROTOCOL PASS: second maintenance window preserves data and updates config");
    $display("ALL PROTOCOL CHECKS PASSED");
    $finish;
  end
endmodule
