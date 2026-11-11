#!/usr/bin/env bash
# Re-runs every cocotb Makefile-variable scenario for the article.
# Run inside geek-eda:0.3-sta after: source /opt/venvs/cocotb/bin/activate
echo "# command: docker run --rm -v \"\$PWD\":/work -w /work geek-eda:0.3-sta bash -lc 'source /opt/venvs/cocotb/bin/activate && bash run.sh'"
echo "# date: 2026-11-03"
echo "# host-toolchain: cocotb 2.1.0 + Icarus Verilog 12.0 (geek-eda:0.3-sta docker)"

echo "==== versions ===="
iverilog -V | head -n 2
python3 --version
cocotb-config --version
make --version | head -n 1

echo "==== scenario 1: baseline make SIM=icarus (all tests in test_counter) ===="
make clean >/dev/null 2>&1
make SIM=icarus
echo "scenario1_exit=$?"

echo "==== scenario 1 artifacts: sim_build contents and cmds.f ===="
ls -1 sim_build/
echo "-- cmds.f --"
cat sim_build/cmds.f

echo "==== scenario 2: COCOTB_TEST_FILTER selects one testcase ===="
make clean >/dev/null 2>&1
make SIM=icarus COCOTB_TEST_FILTER=test_reset_value
echo "scenario2_exit=$?"

echo "==== scenario 3: legacy TESTCASE name (deprecated alias) ===="
make clean >/dev/null 2>&1
make SIM=icarus TESTCASE=test_reset_value 2>&1 | grep -E "Deprecation|running test|TESTS="
echo "scenario3_exit=${PIPESTATUS[0]}"

echo "==== scenario 4: wrong TOPLEVEL (HDL top module name typo) ===="
make clean >/dev/null 2>&1
make SIM=icarus TOPLEVEL=countr 2>&1 | tail -n 6
echo "scenario4_exit=${PIPESTATUS[0]}"

echo "==== scenario 5: wrong COCOTB_TEST_MODULES (python module missing) ===="
make clean >/dev/null 2>&1
make SIM=icarus COCOTB_TEST_MODULES=no_such_module 2>&1 | tail -n 8
echo "scenario5_exit=${PIPESTATUS[0]}"

echo "==== scenario 6: comma-separated module list runs both python files ===="
make clean >/dev/null 2>&1
make SIM=icarus COCOTB_TEST_MODULES=test_counter,test_second
echo "scenario6_exit=$?"

echo "==== scenario 7: legacy PLUSARGS +CYCLES=17 on WIDTH=4 wraps to 1 (FAIL expected) ===="
make clean >/dev/null 2>&1
make SIM=icarus PLUSARGS="+CYCLES=17" 2>&1 | grep -E "deprecated|plusarg CYCLES|after 17|AssertionError|TESTS="
echo "scenario7_exit=${PIPESTATUS[0]}"

echo "==== scenario 8: WIDTH=8 appends COMPILE_ARGS, new COCOTB_PLUSARGS reaches 17 ===="
make clean >/dev/null 2>&1
make SIM=icarus WIDTH=8 COCOTB_PLUSARGS="+CYCLES=17" 2>&1 | grep -E "iverilog|plusarg CYCLES|after 17|TESTS="
echo "scenario8_exit=${PIPESTATUS[0]}"

echo "==== scenario 9: command-line COMPILE_ARGS override wipes cmds.f timescale ===="
make clean >/dev/null 2>&1
make SIM=icarus COMPILE_ARGS="-Pcounter.WIDTH=8" 2>&1 | grep -E "iverilog|precision|ValueError|TESTS=" | head -n 6
echo "scenario9_exit=${PIPESTATUS[0]}"

echo "==== scenario 10: EXTRA_ARGS goes to BOTH compile and vvp run ===="
make clean >/dev/null 2>&1
make SIM=icarus EXTRA_ARGS="-Wall" 2>&1 | grep -E "iverilog|vvp|invalid option" | head -n 4
echo "scenario10_exit=${PIPESTATUS[0]}"

echo "==== scenario 11: SIM_ARGS goes to the vvp run line only ===="
make clean >/dev/null 2>&1
make SIM=icarus SIM_ARGS="-n" 2>&1 | grep -E "iverilog|vvp .* -n|TESTS=" | head -n 4
echo "scenario11_exit=${PIPESTATUS[0]}"

echo "==== ALL SCENARIOS DONE ===="
