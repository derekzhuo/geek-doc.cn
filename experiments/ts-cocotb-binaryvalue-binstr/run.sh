# command: bash run.sh
# date: 2026-10-31
# host-toolchain: Docker geek-eda:0.2 / cocotb 2.1.0
#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
docker run --rm -v "$ROOT:/work" -w /work geek-eda:0.2 bash -lc '
export PATH=/opt/venvs/cocotb/bin:$PATH
if [ ! -e /usr/lib/x86_64-linux-gnu/libpython3.12.so.1.0 ]; then
    apt-get update -qq >/dev/null && apt-get install -y -qq libpython3.12-dev >/dev/null || exit 1
fi
export LIBPYTHON_LOC=/usr/lib/x86_64-linux-gnu/libpython3.12.so.1.0
set +e
printf "\n===== LEGACY: BinaryValue import =====\n"
make clean >/dev/null 2>&1
make MODULE=legacy_test
legacy_status=$?
printf "LEGACY_EXIT=%d\n" "$legacy_status"
printf "\n===== MODERN: LogicArray and value boundaries =====\n"
make clean >/dev/null 2>&1
make MODULE=modern_test
modern_status=$?
printf "MODERN_EXIT=%d\n" "$modern_status"
if [ "$legacy_status" -eq 0 ] || [ "$modern_status" -ne 0 ]; then
    exit 1
fi
exit 0
'
