CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall

all: undo_redo

undo_redo: undo_redo.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: undo_redo
	./undo_redo

clean:
	rm -f undo_redo

.PHONY: all run clean
