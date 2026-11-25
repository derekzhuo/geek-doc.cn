IMAGE := geek-eda:0.5-asic
DOCKER_RUN := docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE)

.PHONY: run probe
run:
	$(DOCKER_RUN) bash run.sh

probe:
	$(DOCKER_RUN) bash probe.sh
