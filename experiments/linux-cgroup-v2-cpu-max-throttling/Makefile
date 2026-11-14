CC ?= gcc
CFLAGS ?= -O2 -std=c11 -Wall -Wextra -pthread

BIN := bin/burner

.PHONY: all clean
all: $(BIN)

$(BIN): src/burner.c
	@mkdir -p bin
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf bin
