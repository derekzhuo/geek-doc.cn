CC = g++
CFLAGS = -O2 -g
LIBS = -lnuma

TARGET = numa_access
SRC = numa_access.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)
