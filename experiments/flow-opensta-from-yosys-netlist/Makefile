IMAGE ?= geek-eda:0.3-sta

.PHONY: run synth sta-setup sta-hold shell

run:
	bash run.sh

synth:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) yosys -s synth.ys

sta-setup:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) sta -no_init -no_splash -exit sta_setup.tcl

sta-hold:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) sta -no_init -no_splash -exit sta_hold.tcl

shell:
	docker run --rm -it -v "$(PWD)":/work -w /work $(IMAGE) bash
