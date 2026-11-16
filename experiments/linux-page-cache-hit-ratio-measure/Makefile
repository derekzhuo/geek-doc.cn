CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra

mincore_check: src/mincore_check.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f mincore_check

.PHONY: clean
