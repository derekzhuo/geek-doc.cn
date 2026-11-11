IMAGE ?= geek-eda:0.3-sta

.PHONY: run clean

run:
	docker run --rm -v "$(CURDIR):/work" -w /work $(IMAGE) bash run.sh

clean:
	rm -rf obj_dir obj_dir_full logs_partial logs_full logs_merged \
	    coverage.dat partial.dat full.dat merged.dat partial.info full.info
