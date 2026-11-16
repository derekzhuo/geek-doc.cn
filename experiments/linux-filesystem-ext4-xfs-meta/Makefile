CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11

meta_bench: meta_bench.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f meta_bench

.PHONY: clean
