CC ?= gcc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra

BIN := bin/thp_bench

.PHONY: all clean
all: $(BIN)

$(BIN): src/thp_bench.c
	@mkdir -p bin
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf bin
