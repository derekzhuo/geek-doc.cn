PYTHON ?= python3

.PHONY: run run-m2 run-m3 run-m4 test clean

run:
	$(PYTHON) run.py

run-m2:
	$(PYTHON) run.py --script scripts/m2_task.json --trace traces/m2-trace.jsonl

run-m3:
	$(PYTHON) scripts/drive_m3.py

run-m4:
	$(PYTHON) scripts/drive_m4.py

test:
	$(PYTHON) -m unittest discover -s tests -v

clean:
	rm -rf workspace traces
