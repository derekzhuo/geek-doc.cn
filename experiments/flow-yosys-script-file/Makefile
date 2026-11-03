# Yosys 脚本文件工程化样例：默认走 geek-eda:0.4-flow docker
# 本机原生装有 yosys + graphviz 时可：make run RUN=""
IMAGE ?= geek-eda:0.4-flow
RUN ?= docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE)

.PHONY: run clean

run: netlist.v acc_rtl.png acc_gate.png

netlist.v acc_rtl.dot acc_gate.dot: adder.v acc.v run.ys
	$(RUN) yosys -s run.ys

acc_rtl.png: acc_rtl.dot
	$(RUN) dot -Tpng -o acc_rtl.png acc_rtl.dot >/dev/null

acc_gate.png: acc_gate.dot
	$(RUN) dot -Tpng -o acc_gate.png acc_gate.dot >/dev/null

clean:
	rm -f netlist.v acc_rtl.dot acc_gate.dot acc_rtl.png acc_gate.png
