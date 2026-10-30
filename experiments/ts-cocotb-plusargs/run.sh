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
printf "cocotb="
cocotb-config --version
iverilog -V | head -n 1
python3 --version
set +e
printf "\n===== GOOD: exported environment and COCOTB_PLUSARGS =====\n"
printf "+ RUN_ID=env_42 make COCOTB_PLUSARGS=\"+MODE=fast +REPEAT=3 +VERBOSE\"\n"
make clean >/dev/null 2>&1
RUN_ID=env_42 make COCOTB_PLUSARGS="+MODE=fast +REPEAT=3 +VERBOSE"
good_status=$?
printf "GOOD_EXIT=%d\n" "$good_status"
printf "\n===== BAD ENV: shell variable is not exported =====\n"
printf "+ RUN_ID=shell_only; make COCOTB_PLUSARGS=\"+MODE=fast +REPEAT=3 +VERBOSE\"\n"
make clean >/dev/null 2>&1
RUN_ID=shell_only
make COCOTB_PLUSARGS="+MODE=fast +REPEAT=3 +VERBOSE"
bad_env_status=$?
printf "BAD_ENV_EXIT=%d\n" "$bad_env_status"
printf "\n===== MISSING COCOTB_PLUSARGS: COCOTB_PLUSARGS omitted =====\n"
printf "+ RUN_ID=env_42 make\n"
make clean >/dev/null 2>&1
RUN_ID=env_42 make
missing_status=$?
printf "MISSING_COCOTB_PLUSARGS_EXIT=%d\n" "$missing_status"
printf "\n===== BAD SIM ARGS: plusargs placed before the design =====\n"
printf "+ RUN_ID=env_42 make SIM_ARGS=\"+MODE=fast +REPEAT=3 +VERBOSE\"\n"
make clean >/dev/null 2>&1
RUN_ID=env_42 make SIM_ARGS="+MODE=fast +REPEAT=3 +VERBOSE"
bad_sim_args_status=$?
printf "BAD_SIM_ARGS_EXIT=%d\n" "$bad_sim_args_status"
if [ "$good_status" -ne 0 ] || [ "$bad_env_status" -eq 0 ] || [ "$missing_status" -eq 0 ] || [ "$bad_sim_args_status" -eq 0 ]; then
    exit 1
fi
exit 0
'
