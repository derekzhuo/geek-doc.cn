CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11 -pthread

alloc_bench: alloc_bench.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f alloc_bench

.PHONY: clean
