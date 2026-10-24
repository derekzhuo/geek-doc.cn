import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly


@cocotb.test()
async def counter_counts_up(dut):
    """Counter increments once per clock after reset."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.load.value = 0
    dut.load_val.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    prev = int(dut.count.value)
    for _ in range(10):
        await RisingEdge(dut.clk)
        cur = int(dut.count.value)
        assert cur == (prev + 1) % 256, f"count {prev} -> {cur}"
        prev = cur
    dut._log.info("counter_counts_up PASSED")


@cocotb.test()
async def counter_load(dut):
    """Synchronous load overrides increment."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.load.value = 0
    dut.load_val.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut.load.value = 1
    dut.load_val.value = 42
    await RisingEdge(dut.clk)          # count <= 42 happens at this edge
    dut.load.value = 0
    await RisingEdge(dut.clk)          # count <= 43 happens at this edge
    await ReadOnly()                   # let NBA updates settle before reading
    assert int(dut.count.value) == 43, f"after load 42 + 1 tick expect 43, got {int(dut.count.value)}"
    dut._log.info("counter_load PASSED")
