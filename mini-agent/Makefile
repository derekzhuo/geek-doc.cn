PYTHON ?= python3

.PHONY: run run-m2 test clean

run:
	$(PYTHON) run.py

run-m2:
	$(PYTHON) run.py --script scripts/m2_task.json --trace traces/m2-trace.jsonl

test:
	$(PYTHON) -m unittest discover -s tests -v

clean:
	rm -rf workspace traces
