import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, with_timeout


@cocotb.test()
async def edge_where_timer_was_needed(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.rst_n.value = 0
    dut.din_v.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    await Timer(10, unit="ns")

    # 本意：释放复位后“留出固定 200ns 稳定时间”再采样。
    # BUG：却去等 busy 的上升沿；din_v 从头到尾不拉高，
    # busy 恒为 0。固定时长应该用 Timer，而不是等一个不会发生的信号事件。
    #
    # 外层包 with_timeout：仿真时间 200ns 内等不到就抛 SimTimeoutError，
    # 用例快速失败（而不是被外部 timeout 命令在墙钟 30s 时杀掉）。
    dut._log.info("C4: want a fixed 200ns delay, wrongly awaiting RisingEdge(busy)")
    await with_timeout(RisingEdge(dut.busy), 200, "ns")

    assert int(dut.busy.value) == 1  # 永远执行不到
