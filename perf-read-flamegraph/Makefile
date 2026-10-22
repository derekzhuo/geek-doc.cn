CC      ?= gcc
CFLAGS  ?= -O2 -g -fno-omit-frame-pointer -std=gnu99
FG      ?= $(HOME)/FlameGraph

.PHONY: all build run-base run-opt record svg clean

all: build

build: hotspot

hotspot: hotspot.c
	$(CC) $(CFLAGS) hotspot.c -o hotspot

run-base: build
	./hotspot base

run-opt: build
	./hotspot opt

# 完整复现：stat / record / report / annotate / 火焰图 / 差分图
record: build
	bash run_lab.sh

# 仅生成三张 SVG
svg: build
	perf record -F 999 -g --call-graph dwarf,16384 -o perf_base.data -- ./hotspot base
	perf record -F 999 -g --call-graph dwarf,16384 -o perf_opt.data  -- ./hotspot opt
	for v in base opt; do \
	  perf script -i perf_$$v.data | $(FG)/stackcollapse-perf.pl > folded_$$v.txt; \
	  $(FG)/flamegraph.pl --countname samples folded_$$v.txt > images/flame_$$v.svg; \
	done
	$(FG)/difffolded.pl folded_opt.txt folded_base.txt | \
	  $(FG)/flamegraph.pl --countname delta > images/flame_diff.svg

clean:
	rm -f hotspot perf_*.data out_*.perf folded_*.txt diff.txt
