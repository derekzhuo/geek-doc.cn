STA_IMAGE ?= geek-eda:0.3-sta

.PHONY: run
run:
	docker run --rm -v "$(PWD)":/work -w /work $(STA_IMAGE) bash run.sh

.PHONY: libs
libs:
	./gen_lib.sh ss 0.40 0.90 0.15 0.02 0.12
	./gen_lib.sh tt 0.20 0.30 0.10 0.05 0.05
	./gen_lib.sh ff 0.05 0.03 0.06 0.12 0.02
