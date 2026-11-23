IVERILOG ?= iverilog
VVP      ?= vvp
LABS     := lab01-clock-divider lab02-debounce lab03-seq-detector-fsm lab04-uart-tx lab05-sync-fifo

.PHONY: test $(LABS) clean

test: $(LABS)

$(LABS):
	@echo "=== $@ ==="
	@mkdir -p $@/sim_build
	$(IVERILOG) -g2005 -I common -o $@/sim_build/sim.vvp $(wildcard $@/tb/*.v $@/rtl/*.v)
	$(VVP) $@/sim_build/sim.vvp

clean:
	rm -rf */sim_build
