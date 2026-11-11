IMAGE ?= geek-eda:0.3-sta

.PHONY: run clean

run:
	docker run --rm -v "$$PWD":/work -w /work $(IMAGE) bash run.sh

clean:
	rm -rf yosys-abc-log*
