# Verilator --threads 1/2/4 对照实验
# 依赖：docker 镜像 geek-eda:0.4-flow（Verilator 5.020）
IMAGE ?= geek-eda:0.4-flow

.PHONY: run clean
run:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) bash run.sh

clean:
	rm -rf obj_big_t* obj_mid_t* obj_stat
