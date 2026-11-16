CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra

dirty_bench: dirty_bench.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f dirty_bench dirty.bin

.PHONY: clean
