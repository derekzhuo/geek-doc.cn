import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def counter_wrong_expect(dut):
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    got = int(dut.q.value)
    dut._log.info("q=%d, expecting 7 (deliberately wrong)", got)
    assert got == 7, "counter mismatch: got %d expect 7" % got
