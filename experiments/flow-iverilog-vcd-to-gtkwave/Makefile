# 复现：VCD 分层导出与时间窗控制
# make run 跑全部对照实验；产物为 depth0/1/2.vcd 与 window.vcd

IVERILOG ?= iverilog
VVP      ?= vvp

.PHONY: all run clean gtkwave

all: run

run:
	bash run.sh

# 需要本机已安装 GTKWave（macOS: brew install --cask gtkwave）
gtkwave:
	gtkwave depth0.vcd

clean:
	rm -f simv_d0 simv_d1 simv_d2 simv_win *.vcd
