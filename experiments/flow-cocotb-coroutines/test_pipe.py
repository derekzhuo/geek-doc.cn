"""cocotb 2.1 协程并发：producer 与 watchdog 两个协程的三种汇合方式。"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, Join, RisingEdge, Timer, gather

BEATS = [0xA1, 0xB2, 0xC3, 0xD4]


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.s_valid.value = 0
    dut.s_data.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def producer(dut, beats):
    """发送侧：复位后连续拍入四拍数据。"""
    dut._log.info("producer 协程启动，等待复位释放")
    await reset_dut(dut)
    for i, data in enumerate(beats):
        dut.s_data.value = data
        dut.s_valid.value = 1
        dut._log.info("producer 第 %d 拍拍入 data=0x%02X", i + 1, data)
        await RisingEdge(dut.clk)
    dut.s_valid.value = 0
    dut._log.info("producer 四拍发完，s_valid 拉低")


async def watchdog(dut, cycles, tag):
    """监测侧：每个时钟沿后 2ns 采样输出口，记录 m_valid 有效的拍。"""
    got = []
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await Timer(2, unit="ns")
        if dut.m_valid.value == 1:
            data = int(dut.m_data.value)
            got.append(data)
            dut._log.info("%s 抓到输出 data=0x%02X（累计 %d 拍）", tag, data, len(got))
    dut._log.info("%s 监测窗口结束，共抓到 %d 拍 %s", tag, len(got),
                  " ".join("0x%02X" % b for b in got))
    return got


@cocotb.test()
async def test_start_soon_then_join(dut):
    """start_soon 并发启动，先 Join 发送侧、再 Join 监测侧。"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    p_task = cocotb.start_soon(producer(dut, BEATS))
    w_task = cocotb.start_soon(watchdog(dut, 10, "watchdog"))

    await Join(p_task)
    dut._log.info("Join(producer) 返回：发送侧已结束，监测侧仍在自己的窗口里")
    got = await Join(w_task)
    assert got == BEATS, f"并发版应抓到全部四拍，实际 {got}"


@cocotb.test()
async def test_combine_waits_both(dut):
    """Combine 等所有任务都结束才返回，效果等同逐个 Join 但写法更紧。"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    p_task = cocotb.start_soon(producer(dut, BEATS))
    w_task = cocotb.start_soon(watchdog(dut, 10, "watchdog"))

    await Combine(p_task, w_task)
    dut._log.info("Combine 返回：producer 与 watchdog 均已结束")
    assert w_task.result() == BEATS


@cocotb.test()
async def test_gather_modern_style(dut):
    """cocotb 2.1 现行写法：gather 直接收协程，全部结束后按序返回结果。"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    p_result, w_result = await gather(producer(dut, BEATS), watchdog(dut, 10, "watchdog"))
    dut._log.info("gather 返回：两个协程均结束，监测结果 %s",
                  " ".join("0x%02X" % b for b in w_result))
    assert w_result == BEATS
    assert p_result is None


@cocotb.test()
async def test_sequential_await_misses_beats(dut):
    """顺序 await：发完才开始监测，监测窗口与发送窗口完全不重叠。"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await producer(dut, BEATS)
    dut._log.info("producer 已全部结束，watchdog 此刻才启动")
    got = await watchdog(dut, 10, "watchdog")
    assert got != BEATS, "顺序版不应抓全四拍"
    dut._log.info("顺序版漏拍 %d 个：并发监测能抓到 %d 拍，顺序只抓到 %d 拍",
                  len(BEATS) - len(got), len(BEATS), len(got))
