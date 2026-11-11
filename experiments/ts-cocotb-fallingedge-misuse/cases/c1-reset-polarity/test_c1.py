import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def active_low_reset_wait_wrong_edge(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

    # BUG：rst_n 是低有效复位。这里把它拉低后，却去等它的上升沿，
    # 而“释放复位（赋值 1）”的语句被写在 await 之后——
    # 没有人能在等待期间把 rst_n 拉高，协程永远挂在这里。
    dut.rst_n.value = 0
    dut.din_v.value = 0
    await Timer(20, unit="ns")
    dut._log.info("C1: about to wait RisingEdge(rst_n) while it is held low ...")
    await RisingEdge(dut.rst_n)

    dut.rst_n.value = 1  # 永远执行不到
    await Timer(10, unit="ns")
    assert int(dut.dout.value) == 0
