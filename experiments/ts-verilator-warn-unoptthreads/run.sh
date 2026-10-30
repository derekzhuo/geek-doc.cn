#!/usr/bin/env bash
set -u

COMMON=(-Wall -Wwarn-UNOPTTHREADS --cc)
rm -rf obj_bad obj_single obj_mtasks obj_hier

verilator --version

printf '\n=== reproduce: 2 threads, at most 2 MTasks ===\n'
printf '%s\n' '$ verilator -Wall -Wwarn-UNOPTTHREADS --cc --threads 2 --threads-max-mtasks 2 --Mdir obj_bad --top-module top top.sv'
verilator "${COMMON[@]}" --threads 2 --threads-max-mtasks 2 \
    --Mdir obj_bad --top-module top top.sv
bad_status=$?
printf '# exit_code: %s\n' "$bad_status"
if [ "$bad_status" -ne 1 ]; then
    printf 'FAIL: expected UNOPTTHREADS to fail this run\n'
    exit 1
fi

printf '\n=== fix: accept a single-threaded model ===\n'
printf '%s\n' '$ verilator -Wall -Wwarn-UNOPTTHREADS --cc --threads 1 --threads-max-mtasks 2 --Mdir obj_single --top-module top top.sv'
verilator "${COMMON[@]}" --threads 1 --threads-max-mtasks 2 \
    --Mdir obj_single --top-module top top.sv
single_status=$?
printf '# exit_code: %s\n' "$single_status"
if [ "$single_status" -ne 0 ]; then
    printf 'FAIL: single-threaded run was not clean\n'
    exit 1
fi
printf 'PASS: single-threaded model accepted\n'

printf '\n=== fix: allow more MTasks with 2 threads ===\n'
printf '%s\n' '$ verilator -Wall -Wwarn-UNOPTTHREADS --cc --threads 2 --threads-max-mtasks 20 --Mdir obj_mtasks --top-module top top.sv'
verilator "${COMMON[@]}" --threads 2 --threads-max-mtasks 20 \
    --Mdir obj_mtasks --top-module top top.sv
mtasks_status=$?
printf '# exit_code: %s\n' "$mtasks_status"
if [ "$mtasks_status" -ne 0 ]; then
    printf 'FAIL: expanded MTask limit was not clean\n'
    exit 1
fi
printf 'PASS: two-thread partition accepted\n'

printf '\n=== control: hierarchy alone, still at most 2 MTasks ===\n'
printf '%s\n' '$ verilator -Wall -Wwarn-UNOPTTHREADS --cc --threads 2 --threads-max-mtasks 2 --Mdir obj_hier --top-module hierarchical counter.sv hierarchical.sv'
verilator "${COMMON[@]}" --threads 2 --threads-max-mtasks 2 \
    --Mdir obj_hier --top-module hierarchical counter.sv hierarchical.sv
hier_status=$?
printf '# exit_code: %s\n' "$hier_status"
if [ "$hier_status" -ne 1 ]; then
    printf 'FAIL: expected hierarchy-only control to retain the warning\n'
    exit 1
fi
printf 'PASS: hierarchy alone did not change the constrained partition\n'
