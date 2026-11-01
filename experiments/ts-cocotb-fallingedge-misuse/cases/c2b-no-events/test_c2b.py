import cocotb
from cocotb.triggers import RisingEdge


@cocotb.test()
async def wait_edge_with_no_events_at_all(dut):
    # 场景②的另一种真实表现：既没有启动时钟，也没有任何 Timer/其它协程，
    # 仿真器事件队列在 0ns 立即耗尽，Icarus 直接结束仿真。
    # cocotb 发现自己还在等边沿、仿真却已结束，报 SimFailure
    # （提示语里直接点名 is your clock running?），退出码非 0，而不是挂死。
    dut.rst_n.value = 1
    dut.din_v.value = 0
    dut._log.info("C2B: no clock, no Timer, awaiting RisingEdge(clk) at 0ns")
    await RisingEdge(dut.clk)
