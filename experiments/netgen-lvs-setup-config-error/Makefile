IMAGE := netgen-lvs-setup-config-error:local

.PHONY: run clean

run:
	docker build -t $(IMAGE) .
	docker run --rm -v "$(CURDIR):/work" $(IMAGE)

clean:
	rm -f results/version.log results/bad.out results/bad.stdout.log results/good.out results/good.stdout.log results/verification.log
