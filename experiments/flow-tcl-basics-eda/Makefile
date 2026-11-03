DOCKER_IMAGE ?= geek-eda:0.4-flow

.PHONY: run sta yosys

run:
	bash run.sh

sta:
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) sta -no_init -exit sta_flow.tcl

yosys:
	docker run --rm -v "$(PWD)":/work -w /work $(DOCKER_IMAGE) yosys -p "tcl ys_flow.tcl"
