// 双时钟异步 FIFO（格雷码指针 + 两级同步），深度 16，宽 8 位
// 注：full/empty 直接由当前寄存器指针比较得到（不用 next 指针反馈门控），
// 既保留正确的满/空语义，又避免 iverilot 对「标志→使能→next→标志」
// 组合环的迭代退化。
module async_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16,
  parameter AW    = 4      // addr width, pointer width = AW+1
) (
  input  wire             wclk,
  input  wire             wrst_n,
  input  wire             wr_en,
  input  wire [WIDTH-1:0] wdata,
  output wire             full,
  input  wire             rclk,
  input  wire             rrst_n,
  input  wire             rd_en,
  output reg  [WIDTH-1:0] rdata,
  output wire             empty
);
  reg [WIDTH-1:0] mem [0:DEPTH-1];

  reg [AW:0] wbin, wgray, rbin, rgray;
  reg [AW:0] rgray_s1, rgray_s2, wgray_s1, wgray_s2;

  // ---------- 写域 ----------
  wire        wen         = wr_en && !full;
  wire [AW:0] wbin_next   = wbin + wen;
  wire [AW:0] wgray_next  = (wbin_next >> 1) ^ wbin_next;

  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n) {wbin, wgray} <= 0;
    else         {wbin, wgray} <= {wbin_next, wgray_next};

  always @(posedge wclk)
    if (wen) mem[wbin[AW-1:0]] <= wdata;

  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n) {rgray_s2, rgray_s1} <= 0;
    else         {rgray_s2, rgray_s1} <= {rgray_s1, rgray};

  // 满：当前写格雷指针已追上读指针格雷码（高两位反相）
  assign full = (wgray == {~rgray_s2[AW:AW-1], rgray_s2[AW-2:0]});

  // ---------- 读域 ----------
  wire        ren         = rd_en && !empty;
  wire [AW:0] rbin_next   = rbin + ren;
  wire [AW:0] rgray_next  = (rbin_next >> 1) ^ rbin_next;

  always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) {rbin, rgray} <= 0;
    else         {rbin, rgray} <= {rbin_next, rgray_next};

  always @(posedge rclk)
    if (ren) rdata <= mem[rbin[AW-1:0]];

  always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) {wgray_s2, wgray_s1} <= 0;
    else         {wgray_s2, wgray_s1} <= {wgray_s1, wgray};

  // 空：当前读格雷指针等于同步过来的写指针
  assign empty = (rgray == wgray_s2);
endmodule
