#!/usr/bin/env bash
# Reproduce KLayout stream-read failure modes plus healthy references.
# stdout and stderr are merged so ERROR lines keep their real order.
set -u
exec 2>&1

KL="${KLAYOUT_BIN:-klayout}"
printf 'TOOL_VERSION: '
"$KL" -v 2>&1 | head -1

rm -f demo.gds demo.oas demo_truncated.gds fake.gds

echo
echo '===== 1. build a healthy GDS2 file ====='
"$KL" -b -r make_gds.rb
printf 'CASE_EXIT make_gds=%s\n' "$?"
ls -l demo.gds

echo
echo '===== 2. healthy GDS read (reference) ====='
INPUT=demo.gds "$KL" -b -r read_gds.rb
printf 'CASE_EXIT healthy=%s\n' "$?"

echo
echo '===== 3. truncated GDS: cut after the first 80 bytes ====='
head -c 80 demo.gds > demo_truncated.gds
INPUT=demo_truncated.gds "$KL" -b -r read_gds.rb
printf 'CASE_EXIT truncated=%s\n' "$?"

echo
echo '===== 4. plain text pretending to be GDS ====='
echo 'this is not a gds file' > fake.gds
INPUT=fake.gds "$KL" -b -r read_gds.rb
printf 'CASE_EXIT fake=%s\n' "$?"

echo
echo '===== 5. OASIS write and read-back ====='
"$KL" -b -r to_oasis.rb
printf 'CASE_EXIT oasis=%s\n' "$?"
