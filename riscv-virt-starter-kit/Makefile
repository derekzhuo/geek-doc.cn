SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: fetch run debug net test clean distclean

fetch:
	bash scripts/fetch.sh

run: fetch
	bash scripts/run.sh

debug:
	bash scripts/debug.sh

net: fetch
	bash scripts/net.sh

test: fetch
	bash scripts/test.sh

clean:
	bash scripts/clean.sh

distclean:
	bash scripts/clean.sh distclean
