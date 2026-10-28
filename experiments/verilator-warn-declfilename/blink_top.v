// blink_top.v —— 修复版：文件名与模块名一致
module blink_top (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);
  reg [23:0] cnt;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 24'd0;
      led <= 1'b0;
    end else if (cnt == 24'd9_999_999) begin
      cnt <= 24'd0;
      led <= ~led;
    end else begin
      cnt <= cnt + 24'd1;
    end
  end
endmodule
