# Yosys 第一次综合最小流程：默认走 geek-eda:0.3-sta docker
# 本机原生装有 yosys 时可：make run YOSYS="yosys"
IMAGE ?= geek-eda:0.3-sta
YOSYS ?= docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE) yosys

.PHONY: run clean

run: netlist.v

netlist.v: counter4.v run.ys
	$(YOSYS) -s run.ys

clean:
	rm -f netlist.v
