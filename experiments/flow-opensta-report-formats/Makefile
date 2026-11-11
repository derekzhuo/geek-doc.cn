IMAGE ?= geek-eda:0.4-flow

.PHONY: run clean

run:
	docker run --rm -v "$(PWD)":/work -w /work $(IMAGE) bash run.sh

clean:
	rm -rf ./*.log reports
