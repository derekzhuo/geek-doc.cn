CC ?= gcc
CFLAGS := -O2 -std=c11 -Wall -Wextra

.PHONY: all clean run

all: bin/nice_bench

bin:
	mkdir -p bin

bin/nice_bench: src/nice_bench.c | bin
	$(CC) $(CFLAGS) $< -o $@

run: all
	bash run.sh

clean:
	rm -rf bin results.txt results-single.txt
