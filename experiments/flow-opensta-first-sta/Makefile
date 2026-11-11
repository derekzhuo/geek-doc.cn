IMAGE ?= geek-eda:0.3-sta

.PHONY: run shell

run:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) sta -no_init -exit run_sta.tcl

shell:
	docker run --rm -it -v "$(PWD)":/work -w /work $(IMAGE) bash
