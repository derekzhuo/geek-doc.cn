# 复现 Yosys flatten 前后对照实验（需要本机有 docker 镜像 geek-eda:0.4-flow）
IMAGE ?= geek-eda:0.4-flow

.PHONY: run clean

run:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) bash run.sh

clean:
	rm -f net_hier.v net_flat.v
