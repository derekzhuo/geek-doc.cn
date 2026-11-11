# 用法：make lint-bad（复现告警）/ make lint-good（修复后干净）/ make run（完整脚本）
IMG ?= geek-eda:0.3-sta
DOCKER_RUN = docker run --rm -v "$(PWD)":/work -w /work $(IMG)

.PHONY: lint-bad lint-good run clean

lint-bad:
	$(DOCKER_RUN) verilator --lint-only -Wall --top-module fifo_top \
	    rtl_bad/fifo_top.v rtl_bad/sync_fifo.v; echo "exit_code=$$? (1 = 有未豁免告警)"

lint-good:
	$(DOCKER_RUN) verilator --lint-only -Wall --top-module fifo_top \
	    rtl_good/fifo_top.v rtl_good/sync_fifo.v; echo "exit_code=$$? (0 = 干净)"

run:
	bash run.sh

clean:
	rm -rf obj_dir
