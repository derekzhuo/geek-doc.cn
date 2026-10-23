# 挂死版与修复版对照：with_timeout 等一个永远不会来的时钟沿
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, with_timeout


@cocotb.test()
async def wait_edge_never_comes(dut):
    """挂死版：忘记启动 wclk，RisingEdge(dut.wclk) 永不到来，500ns 超时。"""
    await with_timeout(RisingEdge(dut.wclk), 500, "ns")


@cocotb.test()
async def wait_edge_fixed(dut):
    """修复版：先起时钟，同一个等待立刻通过。"""
    cocotb.start_soon(Clock(dut.wclk, 10, units="ns").start())
    await with_timeout(RisingEdge(dut.wclk), 500, "ns")
