IMAGE := netgen-lvs-report-reading:local

.PHONY: run clean

run:
	docker build -t $(IMAGE) .
	docker run --rm -v "$(CURDIR):/work" $(IMAGE)

clean:
	rm -f results/version.log results/comp.out results/netgen.stdout.log results/property.out results/property.stdout.log results/verification.log
