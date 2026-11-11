# iCE40 最小链路：Yosys -> nextpnr-ice40 -> icepack（默认走 Docker）
IMAGE ?= geek-eda:0.4-flow
DOCKER_RUN := docker run --rm -v "$(PWD)":/work -w /work $(IMAGE)

DEVICE  := hx1k
PACKAGE := tq144

all: top.bin

top.json: top.v synth.ys
	$(DOCKER_RUN) yosys -s synth.ys

top.asc: top.json top.pcf
	$(DOCKER_RUN) nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
		--json top.json --pcf top.pcf --asc top.asc

top.bin: top.asc
	$(DOCKER_RUN) icepack top.asc top.bin

# 本机原生装了工具链时可用：make run DOCKER_RUN=
run:
	bash ./run.sh

clean:
	rm -f top.json top.asc top.bin

.PHONY: all run clean
