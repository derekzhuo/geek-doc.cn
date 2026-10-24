`timescale 1ns/1ps
// UART 波特率误差失效边界实测（CH340 对接场景的硬件行为复现）：
// TX 以「标称 × (1+err)」真实波特率背靠背连发 0x55/0xAA（无空闲位，最严苛工况），
// RX 按标称波特率中点采样解码并校验停止位；扫描 err 找帧错边界，
// 验证「两端叠加误差 ±2% 工程判据」与理想采样理论极限（±(0.5/9.5)≈±5.3%）之间的裕量。
// r6：rx_byte 带 20bit 看门狗——失步后等不到起始沿判本帧错并续收下一帧，
//     防「等不到 negedge → 事件队列空 → 仿真静默终止」（r5 实测坑）。
module tb;
  localparam real BAUD = 115200.0;
  localparam real BIT_NS = 1.0e9 / BAUD;

  reg line = 1;
  integer k;

  task rx_byte(output [7:0] data, output integer frame_err);
    integer i;
    integer to;
    begin
      frame_err = 0; data = 8'h00; to = 0;
      fork : wait_start
        begin @(negedge line); disable wait_start; end
        begin #(BIT_NS * 20); to = 1; disable wait_start; end
      join
      if (to) begin
        frame_err = 1;   // 看门狗：20 个标称位内没等到起始沿，判帧错
      end else begin
        #(BIT_NS * 1.5);
        for (i = 0; i < 8; i = i + 1) begin
          data[i] = line;
          #(BIT_NS);
        end
        if (line !== 1) frame_err = 1;   // 停止位校验（采样点在 9.5 bit 处）
      end
    end
  endtask

  task tx_stream(input real err, input integer frames);
    integer i; integer f; real bp; reg [7:0] d;
    begin
      bp = BIT_NS * (1.0 + err / 100.0);
      for (f = 0; f < frames; f = f + 1) begin
        d = (f % 2 == 0) ? 8'h55 : 8'hAA;
        line = 0; #(bp);                       // 起始位
        for (i = 0; i < 8; i = i + 1) begin line = d[i]; #(bp); end
        line = 1; #(bp);                       // 停止位后立即下一帧（背靠背）
      end
    end
  endtask

  integer e2; reg [7:0] got; integer ferr; integer tot;
  initial begin
    $display("UART tolerance bench: BAUD=%0d back-to-back 8N1, TX swept, RX nominal midpoint sampling", BAUD);
    for (e2 = -12; e2 <= 12; e2 = e2 + 1) begin
      tot = 0;
      fork
        begin #(BIT_NS); tx_stream(e2 / 2.0, 50); end
        begin
          for (k = 0; k < 50; k = k + 1) begin
            rx_byte(got, ferr);
            if (ferr || got !== ((k % 2 == 0) ? 8'h55 : 8'hAA)) tot = tot + 1;
          end
        end
      join
      $display("MEAS tx_err_x05pct=%0d frames=50 errors=%0d %s", e2, tot,
               (tot == 0) ? "PASS" : "FAIL");
    end
    $finish;
  end
endmodule
