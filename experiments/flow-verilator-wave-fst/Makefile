# Makefile —— geek-eda:0.3-sta 容器内执行；两种波形用独立 Mdir 避免宏冲突
IMAGE ?= geek-eda:0.3-sta
DOCKER = docker run --rm -v "$(PWD)":/work -w /work $(IMAGE)

.PHONY: all vcd fst check clean
all: vcd fst

vcd:
	$(DOCKER) verilator --cc --exe --build -Wall --top-module counter \
	    --Mdir obj_vcd --trace counter.v tb_main.cpp
	$(DOCKER) ./obj_vcd/Vcounter

fst:
	$(DOCKER) verilator --cc --exe --build -Wall --top-module counter \
	    --Mdir obj_fst --trace-fst counter.v tb_main.cpp
	$(DOCKER) ./obj_fst/Vcounter

check:
	ls -l wave.vcd wave.fst
	file wave.vcd wave.fst || true
	xxd wave.fst | head -3
	fst2vcd wave.fst 2>/dev/null | head -20 || true

clean:
	rm -rf obj_vcd obj_fst wave.vcd wave.fst
