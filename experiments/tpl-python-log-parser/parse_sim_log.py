#!/usr/bin/env python3
"""Parse simulator RESULT lines and summarize test failures and seeds."""

import argparse
import re
import sys
from pathlib import Path


RESULT_RE = re.compile(
    r"RESULT test=(?P<test>[A-Za-z0-9_.:-]+) "
    r"seed=(?P<seed>[1-9][0-9]*) status=(?P<status>PASS|FAIL)"
)


class LogFormatError(ValueError):
    """The input contains no result or has a malformed RESULT line."""


def parse_log(path):
    records = []
    with path.open("r", encoding="utf-8") as stream:
        for line_number, raw_line in enumerate(stream, start=1):
            line = raw_line.strip()
            if not line.startswith("RESULT"):
                continue
            match = RESULT_RE.fullmatch(line)
            if match is None:
                raise LogFormatError(
                    "line {}: expected RESULT test=<name> seed=<positive-int> "
                    "status=<PASS|FAIL>".format(line_number)
                )
            records.append((line_number, match.groupdict()))
    if not records:
        raise LogFormatError("no RESULT records found")
    return records


def print_summary(records):
    print("{:>5}  {:<24} {:>10}  {}".format("LINE", "TEST", "SEED", "STATUS"))
    for line_number, fields in records:
        print("{:>5}  {:<24} {:>10}  {}".format(
            line_number, fields["test"], fields["seed"], fields["status"]
        ))

    failures = [item for item in records if item[1]["status"] == "FAIL"]
    failed_seeds = ", ".join(
        "{}({})".format(item[1]["test"], item[1]["seed"])
        for item in failures
    ) or "-"
    print("FAILED_SEEDS: {}".format(failed_seeds))
    print("SUMMARY total={} pass={} fail={}".format(
        len(records), len(records) - len(failures), len(failures)
    ))
    return len(failures)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path, help="simulator log to parse")
    parser.add_argument(
        "--fail-on-test",
        action="store_true",
        help="return 1 when at least one test failed",
    )
    args = parser.parse_args()

    try:
        records = parse_log(args.log)
    except (OSError, UnicodeError, LogFormatError) as error:
        print("INPUT_ERROR {}: {}".format(args.log, error), file=sys.stderr)
        return 2

    failure_count = print_summary(records)
    if args.fail_on_test and failure_count:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
