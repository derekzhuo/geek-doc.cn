IMAGE ?= geek-eda:0.4-flow
YOSYS := docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) yosys

.PHONY: run eq neq version clean

run: version eq neq

version:
	@$(YOSYS) -V

eq:
	@$(YOSYS) -s eq.ys

neq:
	@-$(YOSYS) -s neq.ys

clean:
	@rm -f design.json
