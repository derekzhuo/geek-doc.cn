CC = g++
CFLAGS = -O2 -g -pthread

TARGET = busy_wait_vs_sleep
SRC = busy_wait_vs_sleep.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)
