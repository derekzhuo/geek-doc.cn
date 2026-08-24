CC = g++
CFLAGS = -O2 -g -std=c++17 -pthread

TARGET = spsc_bench
SRC = spsc_bench.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)
