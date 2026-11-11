"""First cocotb 2.1 testbench: drive a D flip-flop from Python."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer


@cocotb.test()
async def test_reset_holds_q_zero(dut):
    """While rst_n is low, q must stay 0 regardless of clock edges."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.d.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    assert dut.q.value == 0, f"in reset q={dut.q.value.binstr}, expected 0"
    dut.rst_n.value = 1


@cocotb.test()
async def test_d_flows_on_rising_edge(dut):
    """d is sampled only at a rising edge; mid-cycle changes must not move q."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.d.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert dut.q.value == 0, f"after reset release q={dut.q.value.binstr}, expected 0"

    # Drive d high: q follows only after the next rising edge.
    dut.d.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert dut.q.value == 1, f"after edge q={dut.q.value.binstr}, expected 1"

    # Pull d low 3 ns after the edge: q must hold until the following edge.
    dut.d.value = 0
    await Timer(3, unit="ns")
    assert dut.q.value == 1, f"q changed mid-cycle: q={dut.q.value.binstr}"
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert dut.q.value == 0, f"after next edge q={dut.q.value.binstr}, expected 0"
