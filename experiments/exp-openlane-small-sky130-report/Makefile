# openlane-small lab — sky130A RTL -> GDS via the OpenLane 1.x official container.
# Requires the golden image: OpenLane repo at /opt/openlane-src/OpenLane,
# PDK installed by volare at $HOME/.volare (PDK_ROOT). This design dir is bind-mounted.
OPENLANE_HOME ?= /opt/openlane-src/OpenLane
PDK_ROOT      ?= $(HOME)/.volare
PDK           ?= sky130A
LAB_DIR       := $(abspath .)
RUNS_DIR      := $(LAB_DIR)/runs
# image tag comes from the locally pulled image, not tool_metadata.yml
# (metadata's 'openlane' line is the app version, not the docker tag)
IMAGE         ?= $(shell docker images --format '{{.Repository}}:{{.Tag}}' | grep -m1 'efabless/openlane')

run:
	sudo rm -rf $(RUNS_DIR)
	mkdir -p $(RUNS_DIR)
	cd $(OPENLANE_HOME) && \
	docker run --rm \
	  -v $(OPENLANE_HOME):/openlane \
	  -v $(PDK_ROOT):$(PDK_ROOT) \
	  -v $(LAB_DIR):/designs/small_counter \
	  -w /openlane \
	  -e PDK_ROOT=$(PDK_ROOT) \
	  -e PDK=$(PDK) \
	  -e PWD=/openlane \
	  $(IMAGE) \
	  ./flow.tcl -design /designs/small_counter -tag golden_smoke -overwrite

# acceptance greps (harvest.py parses the same artifacts):
#   runs/<tag>/reports/synthesis/*-area.stat.rpt  (yosys stat)
#   runs/<tag>/logs/routing/*-drc.log             ("No DRC errors")
#   runs/<tag>/results/lvs/*.lvs.parsed.txt        ("LVS OK" / CORRECT)

clean:
	sudo rm -rf runs

.PHONY: run clean
