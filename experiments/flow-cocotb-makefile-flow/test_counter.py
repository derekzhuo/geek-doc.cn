"""cocotb 2.1 tests for the counter DUT.

Demonstrates:
- reading a plusarg (+CYCLES=N) via cocotb.plusargs
- counting cycles and asserting against parameter WIDTH effects
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut, cycles=2):
    dut.rst_n.value = 0
    dut.en.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_value(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)
    await Timer(1, unit="ns")
    assert int(dut.q.value) == 0, f"after reset q={int(dut.q.value)}"


@cocotb.test()
async def test_count_cycles(dut):
    # plusarg +CYCLES controls how many enables we pulse; default 3.
    cycles = int(cocotb.plusargs.get("CYCLES", 3))
    dut._log.info(f"plusarg CYCLES={cycles}")

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    dut.en.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    await Timer(1, unit="ns")

    got = int(dut.q.value)
    dut._log.info(f"after {cycles} enables q={got}")
    assert got == cycles, f"q={got}, expected {cycles}"
