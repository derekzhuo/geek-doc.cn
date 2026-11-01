"""Minimal cocotb 2.1 testbench: clock, reset, driver coroutine, assertions."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (
    RisingEdge,
    FallingEdge,
    Timer,
    with_timeout,
    SimTimeoutError,
)
from cocotb.types import LogicArray


async def reset_seq(dut, cycles=2):
    """Synchronous active-low reset: keep rst_n low for a few clock edges."""
    dut.rst_n.value = 0
    dut.en.value = 0
    dut.load.value = 0
    dut.din.value = LogicArray("0000")
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1


async def drive_cfg(dut, en, load, din):
    """Driver: apply one config word and wait one settled clock edge."""
    dut.en.value = en
    dut.load.value = load
    dut.din.value = LogicArray(din)
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")  # sample after RTL nonblocking updates settle


@cocotb.test()
async def test_reset_value(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_seq(dut)
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert dut.q.value == 0, f"after reset q={dut.q.value.binstr}, expected 0000"


@cocotb.test()
async def test_count_and_load(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_seq(dut)

    # Count 3 cycles: 0 -> 1 -> 2 -> 3.
    for _ in range(3):
        await drive_cfg(dut, en=1, load=0, din="0000")
    assert dut.q.value == 3, f"count q={int(dut.q.value)}, expected 3"

    # load takes priority over en: q becomes din.
    await drive_cfg(dut, en=1, load=1, din="1010")
    assert dut.q.value == LogicArray("1010"), (
        f"load q={dut.q.value.binstr}, expected 1010"
    )

    # Held with en=0: q must stay.
    await drive_cfg(dut, en=0, load=0, din="0000")
    assert dut.q.value == LogicArray("1010"), "q changed while en was low"


@cocotb.test()
async def test_timeout_rescue(dut):
    """A wait that can never complete must be bounded by with_timeout."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_seq(dut)

    dut.load.value = 0  # held constant, so FallingEdge never happens
    rescued = False
    try:
        await with_timeout(FallingEdge(dut.load), 50, timeout_unit="ns")
    except SimTimeoutError:
        rescued = True
        dut._log.info("wait rescued by with_timeout after 50 ns")

    assert rescued, "unreachable edge wait returned without SimTimeoutError"
    await Timer(10, unit="ns")
