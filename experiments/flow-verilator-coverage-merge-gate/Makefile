IMAGE ?= geek-eda:0.4-flow

.PHONY: run clean

run:
	docker run --rm -v "$(CURDIR):/work" -w /work $(IMAGE) bash run.sh

clean:
	rm -rf obj_dir coverage.dat coverage_seed*.dat merged.dat report.info
