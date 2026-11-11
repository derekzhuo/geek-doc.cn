STA_IMAGE ?= geek-eda:0.4-flow

.PHONY: run
run:
	docker run --rm -v "$(PWD)":/work -w /work $(STA_IMAGE) bash run.sh
