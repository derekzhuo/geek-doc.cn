import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


@cocotb.test()
async def edge_usage_all_correct(dut):
    # 1) 先启动时钟，之后才在 clk 上等边沿
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    # 2) 低有效复位：用 Timer 保持固定低电平时间，再主动释放
    dut.rst_n.value = 0
    dut.din_v.value = 0
    await Timer(25, unit="ns")
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # 3) 在会真实跳变的寄存器输出上做同步
    dut.din_v.value = 1
    dut.din.value = 5
    await RisingEdge(dut.clk)
    dut.din_v.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.dout.value) == 5, f"dout={dut.dout.value}"
    dut._log.info("GOOD: dout sampled as 5, all edge waits returned")
