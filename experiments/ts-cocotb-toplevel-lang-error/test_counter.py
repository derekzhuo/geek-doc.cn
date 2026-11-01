import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer


@cocotb.test()
async def counter_increments_after_reset(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    await cocotb.start(clock.start())

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    assert int(dut.count.value) == 0, f"reset value={dut.count.value}"

    dut.rst_n.value = 1
    for expected in range(1, 6):
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")
        got = int(dut.count.value)
        assert got == expected % 16, f"after {expected} cycles count={got}"
