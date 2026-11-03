#!/usr/bin/env bash
# 最小 RTL 工程 Git 流程演示：init -> feature -> sim 回归 -> merge -> tag -> ignore 证据 -> vendor 子模块
# 全程在 evidence-src/flow-git-rtl-versioning/ 下用相对路径执行
set -u
echo "# command: bash demo-git-flow.sh (demo-repo: init/feature/sim/merge/tag/ignore/submodule)"
echo "# date: 2026-11-04"
echo "# host-toolchain: git $(git --version | awk '{print $3}') / $(iverilog -V 2>/dev/null | head -1) / $(make --version | head -1)"
echo

rm -rf demo-repo vendor-ip-repo

echo "===== [0] 工具版本 ====="
git --version
iverilog -V 2>/dev/null | head -1
make --version | head -1
echo

echo "===== [1] git init 建仓（main 主线）====="
git init -q -b main demo-repo
echo "OK: demo-repo 初始化完成（初始分支 main）"
cd demo-repo
git config user.name "rtl-eng"
git config user.email "rtl-eng@example.local"
mkdir -p rtl tb

cat > .gitignore <<'EOF'
# 仿真/综合中间产物，全部可由源码重建
*.vvp
*.vcd
*.fst
build/
obj_dir/
sim_build/
# 工具杂项
*.log
.DS_Store
EOF

cat > rtl/counter4.v <<'EOF'
`timescale 1ns/1ps
module counter4 (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] q,
    output wire       carry
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 4'd0;
    else        q <= q + 4'd1;
  end
  assign carry = (q == 4'd15);
endmodule
EOF

cat > tb/tb_counter4.v <<'EOF'
`timescale 1ns/1ps
module tb_counter4;
  reg clk = 0;
  reg rst_n = 0;
  wire [3:0] q;
  wire carry;
  counter4 dut (.clk(clk), .rst_n(rst_n), .q(q), .carry(carry));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_counter4);
    #12 rst_n = 1;
    repeat (15) @(posedge clk); #1;
    if (q !== 4'd15 || carry !== 1'b1)
      $display("TEST FAIL tb_counter4 q=%0d carry=%b", q, carry);
    else begin
      @(posedge clk); #1;
      if (q !== 4'd0) $display("TEST FAIL tb_counter4 wrap q=%0d", q);
      else           $display("TEST PASS tb_counter4");
    end
    #10 $finish;
  end
endmodule
EOF

cat > Makefile <<'EOF'
RTL   := rtl/counter4.v
TB    := tb/tb_counter4.v
BUILD := build
SIM   := $(BUILD)/sim.vvp

.PHONY: sim clean
sim: $(SIM)
	vvp -n $(SIM)

$(SIM): $(RTL) $(TB)
	mkdir -p $(BUILD)
	iverilog -g2012 -Wall -o $@ $(TB) $(RTL)

clean:
	rm -rf $(BUILD)
EOF

cat > README.md <<'EOF'
# counter4 demo

4-bit counter with async reset. `make sim` runs the self-checking testbench.
EOF

git add .gitignore Makefile README.md rtl tb
git commit -m "init: counter4 rtl, self-checking tb, make sim"
git log --oneline
echo

echo "===== [2] 开 feature 分支改 RTL：增加计数使能 en ====="
git checkout -b feature/count-enable

cat > rtl/counter4.v <<'EOF'
`timescale 1ns/1ps
module counter4 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [3:0] q,
    output wire       carry
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= 4'd0;
    else if (en)     q <= q + 4'd1;
  end
  assign carry = (q == 4'd15) & en;
endmodule
EOF

cat > tb/tb_counter4.v <<'EOF'
`timescale 1ns/1ps
module tb_counter4;
  reg clk = 0;
  reg rst_n = 0;
  reg en = 1;
  wire [3:0] q;
  wire carry;
  counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_counter4);
    #12 rst_n = 1;
    @(posedge clk); #1; en = 0;     // 暂停 4 拍，q 保持
    repeat (4) @(posedge clk); #1;
    if (q !== 4'd1) $display("TEST FAIL hold q=%0d", q);
    en = 1;                          // 恢复计数
    repeat (14) @(posedge clk); #1;
    if (q !== 4'd15 || carry !== 1'b1)
      $display("TEST FAIL count q=%0d carry=%b", q, carry);
    else begin
      @(posedge clk); #1;
      if (q !== 4'd0) $display("TEST FAIL wrap q=%0d", q);
      else           $display("TEST PASS tb_counter4");
    end
    #10 $finish;
  end
endmodule
EOF

echo "--- [2a] 暂存前先看改动面（Review 检查点：只动 rtl/tb）---"
git diff --stat
echo
echo "--- [2b] feature 分支上跑回归 ---"
make sim
echo
git add rtl tb
echo "--- [2c] 已暂存内容相对 main 的差异（合并评审看这一份）---"
git diff --cached --stat main
git commit -m "feat(rtl): add count-enable, tb covers hold and resume"
git log --oneline
echo

echo "===== [3] 回主线 --no-ff 合并，保留分支拓扑 ====="
git checkout main
git merge --no-ff feature/count-enable -m "merge: feature/count-enable into main"
echo

echo "===== [4] 合入后回归 + 打版本标签 v1.0 ====="
make sim
git tag -a v1.0 -m "release v1.0: counter4 with count-enable"
git log --oneline --graph --decorate
git tag -n
echo

echo "===== [5] .gitignore 证据：产物满目录，git 视野干净 ====="
ls build
echo "--- git status --short（应无输出）---"
git status --short
echo "--- git check-ignore -v（逐条给出命中规则）---"
git check-ignore -v build/sim.vvp build/wave.vcd obj_dir/ sim_build/x.vvp
echo "--- git status --ignored --short（!! 开头即被忽略）---"
git status --ignored --short
echo "--- 受版本管理的文件清单（只有源码）---"
git ls-files
echo

echo "===== [6] vendor IP：本地路径演示 submodule add/status（无网络）====="
cd ..
git init -q -b main vendor-ip-repo
echo "OK: vendor-ip-repo 初始化完成（独立 IP 仓）"
cd vendor-ip-repo
git config user.name "ip-team"
git config user.email "ip-team@example.local"
mkdir -p rtl
cat > rtl/uart_tx.v <<'EOF'
`timescale 1ns/1ps
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output reg        tx_ready,
    output reg        txd
);
  // 教学用最小占位 IP，仅演示 vendor 版本管理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin tx_ready <= 1'b1; txd <= 1'b1; end
  end
endmodule
EOF
git add rtl
git commit -m "ip: uart_tx v0.3 placeholder"
git tag -a v0.3 -m "uart_ip v0.3"
cd ../demo-repo
git -c protocol.file.allow=always submodule add -q ../vendor-ip-repo vendor/uart_ip
echo "OK: vendor/uart_ip 子模块登记完成（gitlink mode 160000）"
echo "--- submodule add 之后的 git status ---"
git status --short
echo "--- .gitmodules 内容 ---"
cat .gitmodules
git add .gitmodules vendor/uart_ip
git commit -m "vendor: track uart_ip v0.3 as submodule"
echo
echo "===== [7] 最终历史 ====="
git log --oneline --graph --decorate
echo "DEMO DONE"
