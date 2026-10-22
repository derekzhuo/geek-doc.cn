# cpp-beginner-practice Makefile —— 与本站演示约定一致：-O0 -g 保留符号，C++17
CXX     = g++
CXXFLAGS = -O0 -g -Wall -Wextra -std=c++17

TARGETS = book_mgmt grade_system calculator word_count linked_list cli_tool

all: $(TARGETS)

book_mgmt: book_mgmt.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

grade_system: grade_system.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

calculator: calculator.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

word_count: word_count.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

linked_list: linked_list.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

cli_tool: cli_tool.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

run-book: book_mgmt
	./book_mgmt

run-grade: grade_system
	./grade_system

run-calc: calculator
	./calculator

run-stats: word_count
	./word_count $(FILE)

run-list: linked_list
	./linked_list

run-cli: cli_tool
	./cli_tool $(ARGS)

clean:
	rm -f $(TARGETS)

.PHONY: all run-book run-grade run-calc run-stats run-list run-cli clean
