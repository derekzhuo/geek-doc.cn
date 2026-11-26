.PHONY: image run clean

image:
	docker build --build-arg OPENROAD_COMMIT=6f3f28cc85 -t geek-eda:0.5-asic .

run:
	docker run --rm -v "$(CURDIR):/work" -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'

clean:
	rm -rf results .history_sta
