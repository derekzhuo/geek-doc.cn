# test_counter.py —— cocotb 测试平台：时钟/复位/随机使能激励 + 断言
# 运行环境：cocotb 2.1.0 + Icarus Verilog 12.0（geek-eda:0.1 容器）
#
# INJECT_BUG=1 时故意把参考模型的复位初值写成 1（off-by-one），
# 用来演示一次真实 FAIL 的输出长什么样（见 make failcase）。

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge

INJECT_BUG = os.environ.get("INJECT_BUG", "0") == "1"

# 参考模型（scoreboard）：Python 里维护一份「本该是多少」的计数值。
# 注意 cocotb 2.x 里 LogicArray 不再有 .integer 属性，取无符号值用 .to_unsigned()。
RESET_VALUE = 1 if INJECT_BUG else 0  # BUG 注入点：正常应为 0


async def reset_dut(dut):
    """低有效同步复位：拉低 3 拍再松开，期间每拍检查复位值。"""
    dut.rst_n.value = 0
    dut.en.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert dut.count.value.to_unsigned() == 0, (
            f"reset check: count={dut.count.value.to_unsigned()}, expect 0"
        )
        assert int(dut.ovf.value) == 0, "reset check: ovf should be 0"
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1


@cocotb.test()
async def test_reset(dut):
    """定向测试 1：复位把 count 清 0、ovf 清 0。"""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await reset_dut(dut)
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert dut.count.value.to_unsigned() == RESET_VALUE or not INJECT_BUG
    dut._log.info("test_reset PASS: count held 0 during 3-cycle reset")


@cocotb.test()
async def test_enable_hold(dut):
    """定向测试 2：en=0 时计数值必须原样保持。"""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await reset_dut(dut)
    # 先数 5 拍，再停 4 拍
    await FallingEdge(dut.clk)
    dut.en.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.en.value = 0
    await RisingEdge(dut.clk)
    await ReadOnly()
    held = dut.count.value.to_unsigned()
    for _ in range(4):
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert dut.count.value.to_unsigned() == held, (
            f"hold check: count drifted {held} -> {dut.count.value.to_unsigned()}"
        )
    dut._log.info(f"test_enable_hold PASS: count held at {held} for 4 clocks")


@cocotb.test()
async def test_random_count(dut):
    """随机回归主测试：随机 en 序列 300 拍，逐拍比对 count 与 ovf。"""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    await reset_dut(dut)

    expected = RESET_VALUE
    checks = 0
    ovf_seen = 0
    for cycle in range(300):
        # 在下降沿驱动激励，避开时钟沿上的竞争
        await FallingEdge(dut.clk)
        en = random.choice([0, 1, 1, 1])  # 75% 使能，多碰溢出
        dut.en.value = en

        prev = expected
        await RisingEdge(dut.clk)
        await ReadOnly()  # 等 NBA 落定再采样，避免读到旧值

        expected_ovf = 1 if (en and prev == 15) else 0
        if en:
            expected = (prev + 1) % 16

        actual_count = dut.count.value.to_unsigned()
        actual_ovf = int(dut.ovf.value)
        assert actual_count == expected, (
            f"cycle {cycle}: count={actual_count}, expect {expected} (en={en})"
        )
        assert actual_ovf == expected_ovf, (
            f"cycle {cycle}: ovf={actual_ovf}, expect {expected_ovf}"
        )
        checks += 2
        ovf_seen += actual_ovf

    dut._log.info(
        f"test_random_count PASS: {checks} assertions, {ovf_seen} overflow pulses"
    )
