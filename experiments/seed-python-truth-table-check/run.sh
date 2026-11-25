#!/bin/sh
set -eu
cd "$(dirname "$0")"
python3 --version
python3 truth_table_check.py
