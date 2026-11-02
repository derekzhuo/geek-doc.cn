# 同一计数器设计，对照 Verilator 5.x 的两种仿真模式：
#   make run       在 geek-eda 容器里顺序跑 --binary 与 --cc 两种模式
#   make clean     删除两种模式各自的 obj_dir 构建目录
IMAGE ?= geek-eda:0.3-sta

.PHONY: run clean

run:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) bash run.sh

clean:
	rm -rf obj_dir_bin obj_dir_cc
