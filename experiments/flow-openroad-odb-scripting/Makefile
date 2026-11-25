.PHONY: run clean

run:
	docker run --rm -v "$(CURDIR):/work" -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'

clean:
	rm -rf results
