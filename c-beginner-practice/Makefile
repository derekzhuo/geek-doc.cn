# c-beginner-practice Makefile —— 与本站演示约定一致：-O0 -g 保留符号
CC      = gcc
CFLAGS  = -O0 -g -Wall -Wextra -std=gnu99

TARGETS = guess_number calculator student_mgmt linked_list text_stats sorting

all: $(TARGETS)

guess_number: guess_number.c
	$(CC) $(CFLAGS) $< -o $@

calculator: calculator.c
	$(CC) $(CFLAGS) $< -o $@

student_mgmt: student_mgmt.c
	$(CC) $(CFLAGS) $< -o $@

linked_list: linked_list.c
	$(CC) $(CFLAGS) $< -o $@

text_stats: text_stats.c
	$(CC) $(CFLAGS) $< -o $@

sorting: sorting.c
	$(CC) $(CFLAGS) $< -o $@

run-guess: guess_number
	./guess_number

run-calc: calculator
	./calculator $(ARGS)

run-student: student_mgmt
	./student_mgmt

run-list: linked_list
	./linked_list

run-stats: text_stats
	./text_stats $(FILE)

run-sort: sorting
	./sorting

clean:
	rm -f $(TARGETS)

.PHONY: all run-guess run-calc run-student run-list run-stats run-sort clean
