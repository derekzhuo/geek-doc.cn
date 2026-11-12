CC ?= gcc
CFLAGS := -O3 -std=c11 -Wall -Wextra -fopenmp -march=native
CPPFLAGS := -DSTREAM_N=10000000 -DNTIMES=20

.PHONY: all clean run

all: bin/stream_bench

bin:
	mkdir -p bin

bin/stream_bench: src/stream_bench.c | bin
	$(CC) $(CFLAGS) $(CPPFLAGS) $< -o $@ -lm

run: all
	bash run.sh

clean:
	rm -rf bin results.txt
