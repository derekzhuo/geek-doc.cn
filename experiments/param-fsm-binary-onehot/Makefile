IMAGE ?= geek-eda:0.4-flow

.PHONY: run sim clean

run:
	bash run.sh

sim:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) \
		iverilog -g2012 -o work/sim rtl/fsm_walker.v tb/tb_fsm_walker.v
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) vvp work/sim

clean:
	rm -rf work
