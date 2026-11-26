IMAGE ?= geek-eda:0.5-asic

.PHONY: run clean
run:
	docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE) bash -lc 'bash run.sh'

clean:
	rm -rf results
