IMAGE ?= geek-eda:0.3-sta

.PHONY: run native

# 在 geek-eda 容器里跑完整证据链（推荐，Yosys 0.33）
run:
	docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE) bash run.sh

# 本机原生装了 yosys 时可直接跑
native:
	bash run.sh
