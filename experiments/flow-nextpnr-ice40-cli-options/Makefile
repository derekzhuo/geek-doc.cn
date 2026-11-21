IMAGE ?= geek-eda:0.4-flow
DOCKER_RUN ?= docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE)

.PHONY: run clean

run:
	$(DOCKER_RUN) bash ./run.sh 2>&1 | tee run1.log

clean:
	rm -rf build run1.log
