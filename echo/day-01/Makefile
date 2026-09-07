.PHONY: all clean run-server run-client

CC       = gcc
CFLAGS   = -O0 -g -Wall -Wextra

all: bin/echo-server bin/echo-client

bin/echo-server: server.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin/echo-client: client.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin:
	mkdir -p bin

run-server: bin/echo-server
	./bin/echo-server

run-client: bin/echo-client
	./bin/echo-client 127.0.0.1 9090

clean:
	rm -rf bin
