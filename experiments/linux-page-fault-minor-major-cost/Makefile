CC ?= gcc
CFLAGS := -O2 -std=c11 -Wall -Wextra

.PHONY: all clean run

all: bin/pf_bench

bin:
	mkdir -p bin

bin/pf_bench: src/pf_bench.c | bin
	$(CC) $(CFLAGS) $< -o $@

run: all
	bash run.sh

clean:
	rm -rf bin results.txt
