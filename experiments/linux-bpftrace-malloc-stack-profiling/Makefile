CC ?= cc
CFLAGS ?= -O2 -g -fno-omit-frame-pointer -fno-pie -no-pie -fno-inline-functions -std=c11 -Wall -Wextra

all: malloc_hotspots

malloc_hotspots: malloc_hotspots.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f malloc_hotspots

.PHONY: all clean
