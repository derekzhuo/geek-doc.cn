# Convenience wrappers. The CI definition lives in .github/workflows/verilator-ci.yml.
# Native:  make run        (needs verilator, g++, make on PATH)
# Docker:  make run VERILATOR_IMG=geek-eda:0.3-sta
VERILATOR_IMG ?=

.PHONY: run clean

run:
	VERILATOR_IMG="$(VERILATOR_IMG)" ./run.sh

clean:
	rm -rf obj_dir build
