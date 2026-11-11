IMAGE ?= geek-eda:0.3-sta
OUTPUTS = netlist_default.v netlist_clean.v design.json design.blif

.PHONY: run clean check

run: $(OUTPUTS)

$(OUTPUTS): counter4.v run.ys
	docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE) yosys -s run.ys

check:
	@echo "--- file sizes (expect 510 / 1699 / 1440 / 8822 / 1334) ---"
	wc -c counter4.v $(OUTPUTS)
	@echo "--- cell instances in -noattr -noexpr -nodec netlist (expect 13) ---"
	@grep -F -c '\$$_' netlist_clean.v

clean:
	rm -f $(OUTPUTS)
