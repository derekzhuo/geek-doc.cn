import cocotb
from cocotb.triggers import RisingEdge, Timer


async def unrelated_timer_activity(dut):
    # 与 clk 无关的后台活动：只靠 Timer 周期性翻转 din，
    # 让仿真器事件队列始终非空（仿真时间会一直往前走）。
    while True:
        await Timer(13, unit="ns")
        dut.din_v.value = int(dut.din_v.value) ^ 1


@cocotb.test()
async def wait_clock_edge_before_clock_started(dut):
    # BUG：没有任何地方 start Clock(dut.clk)，却在 clk 上等上升沿。
    # 后台 Timer 活动让仿真不会因为“没有事件”而结束，
    # 于是 clk 永远不跳变，RisingEdge 永久等待，只能被外部 timeout 杀掉。
    dut.rst_n.value = 1
    dut.din_v.value = 0
    cocotb.start_soon(unrelated_timer_activity(dut))
    dut._log.info("C2: awaiting RisingEdge(clk), Clock was never started")
    await RisingEdge(dut.clk)

    assert int(dut.dout.value) == 0  # 永远执行不到
