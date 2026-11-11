"""Randomized cocotb 2.1 testbench for the 8-bit saturating adder.

Stimulus comes from Python's standard `random`, which cocotb re-seeds
for every test from COCOTB_RANDOM_SEED (mixed with the test name).
The same regression seed therefore reproduces the exact same stream.
"""

import random

import cocotb
from cocotb.triggers import Timer

N_TXNS = 300


@cocotb.test()
async def test_random_sat_add(dut):
    dut._log.info("per-test cocotb.RANDOM_SEED = %d", cocotb.RANDOM_SEED)
    mismatches = 0
    first_bad = None

    for i in range(N_TXNS):
        a = random.getrandbits(8)
        b = random.getrandbits(8)
        dut.a.value = a
        dut.b.value = b
        await Timer(1, unit="ns")  # let combinational outputs settle

        got = int(dut.sum.value)
        exp = min(a + b, 255)
        if got != exp:
            mismatches += 1
            if first_bad is None:
                first_bad = (i, a, b, got, exp)
                dut._log.error(
                    "mismatch at txn %d: a=%d b=%d got sum=%d expected %d",
                    i, a, b, got, exp,
                )

    dut._log.info("applied %d random transactions, mismatches=%d", N_TXNS, mismatches)
    assert mismatches == 0, f"{mismatches} mismatches, first={first_bad}"
