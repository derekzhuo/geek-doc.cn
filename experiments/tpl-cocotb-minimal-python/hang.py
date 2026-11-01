"""Deliberate hang demo: waits for an edge that never comes.

Run with COCOTB_TEST_MODULES=hang; an outer `timeout` is expected to kill
it with exit 124. This file is not part of the normal test module.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


@cocotb.test()
async def test_hang_on_constant(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst_n.value = 1
    dut.load.value = 0
    await Timer(20, unit="ns")  # settle past the initial x->0 edge
    # The clock keeps the simulator alive and load never toggles again:
    # this edge never arrives, so the outer timeout has to kill the run.
    await FallingEdge(dut.load)
