// gpio_waive.v —— 豁免版：一个文件装多个小模块，用 lint_off 显式豁免
/* verilator lint_off DECLFILENAME */
module gpio_ctrl (
    input  wire       clk,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
  always @(posedge clk) dout <= din;
endmodule
/* verilator lint_on DECLFILENAME */
