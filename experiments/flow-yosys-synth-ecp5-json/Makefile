IMAGE ?= geek-eda:0.4-flow
DOCKER_RUN ?= docker run --rm -v "$(CURDIR):/work" -w /work $(IMAGE)

.PHONY: run clean
run:
	$(DOCKER_RUN) bash ./run.sh

clean:
	rm -rf build
