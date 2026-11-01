import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def wait_edge_on_stable_combinational_signal(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.rst_n.value = 1
    dut.din_v.value = 0

    await Timer(20, unit="ns")
    # comb_gate = din_v & rst_n，是纯组合输出。
    # BUG：两个输入此后都不再变化，comb_gate 恒为 0，
    # 组合逻辑信号上没有任何事件，RisingEdge 永远等不到。
    dut._log.info("C3: comb_gate=%s, waiting for its rising edge that never comes",
                  dut.comb_gate.value)
    await RisingEdge(dut.comb_gate)

    dut.din_v.value = 1  # 永远执行不到
