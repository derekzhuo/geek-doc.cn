`timescale 1ns/1ns
// DUT：收到 in_valid 的数据，一拍后输出 data+1
// +inject_bug 时人为算成 data+2，供 scoreboard 抓 MISMATCH
module dut(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       in_valid,
  input  logic [7:0] in_data,
  output logic       out_valid,
  output logic [7:0] out_data
);
  logic bug_mode;
  initial begin
    bug_mode = 1'b0;
    if ($test$plusargs("inject_bug")) bug_mode = 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      out_data  <= 8'd0;
    end else begin
      out_valid <= in_valid;
      if (in_valid)
        out_data <= in_data + (bug_mode ? 8'd2 : 8'd1);
    end
  end
endmodule
