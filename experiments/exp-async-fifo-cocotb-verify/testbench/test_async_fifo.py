# test_async_fifo.py — cocotb regression for async FIFO.
# Deterministic random seed; asserts FIFO data integrity across clock domains,
# exercises full (write-side backpressure) and empty (read-side stall).
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

W, D = 8, 16


async def reset(dut):
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wdata.value = 0
    for _ in range(4):
        await RisingEdge(dut.wclk)
        await RisingEdge(dut.rclk)
    dut.wrst_n.value = 1
    dut.rrst_n.value = 1
    await RisingEdge(dut.wclk)
    await RisingEdge(dut.rclk)


async def wait_not_empty(dut, max_cycles=40):
    # 打拍同步 + 寄存 empty 有数拍延迟，轮询标志而不是数固定周期
    for _ in range(max_cycles):
        await RisingEdge(dut.rclk)
        if int(dut.empty.value) == 0:
            return
    raise AssertionError("empty never deasserted after write")


@cocotb.test()
async def single_write_read(dut):
    cocotb.start_soon(Clock(dut.wclk, 7, units="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 11, units="ns").start())
    await reset(dut)

    dut.wdata.value = 0xA5
    dut.wr_en.value = 1
    await RisingEdge(dut.wclk)
    dut.wr_en.value = 0

    await wait_not_empty(dut)
    dut.rd_en.value = 1
    await FallingEdge(dut.rclk)
    got = int(dut.rdata.value)
    assert got == 0xA5, f"expected 0xA5 got {got:#x}"
    await RisingEdge(dut.rclk)
    dut.rd_en.value = 0


@cocotb.test()
async def random_back_to_back(dut):
    cocotb.start_soon(Clock(dut.wclk, 6, units="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 9, units="ns").start())
    await reset(dut)
    rng = random.Random(20261020)

    written, received = [], []
    n_tx = 200

    async def writer():
        # 负沿采样/驱动：正沿后立即读 full 会撞上寄存器 NBA 更新（读到旧值），
        # 旧 full=0 时写入已满 FIFO 会覆盖丢数据，读者永远等不齐
        sent = 0
        while sent < n_tx:
            await FallingEdge(dut.wclk)
            if int(dut.full.value) == 0 and rng.random() < 0.8:
                v = rng.randrange(256)
                dut.wdata.value = v
                dut.wr_en.value = 1
                written.append(v)
                sent += 1
            else:
                dut.wr_en.value = 0
        await FallingEdge(dut.wclk)
        dut.wr_en.value = 0

    async def reader():
        while len(received) < n_tx:
            await FallingEdge(dut.rclk)
            if int(dut.empty.value) == 0 and rng.random() < 0.7:
                received.append(int(dut.rdata.value))
                dut.rd_en.value = 1
            else:
                dut.rd_en.value = 0
        dut.rd_en.value = 0

    w = cocotb.start_soon(writer())
    r = cocotb.start_soon(reader())
    await w.join()
    await r.join()

    assert len(received) == n_tx
    assert written == received, "FIFO data order/content mismatch across clock domains"
    dut._log.info(f"{n_tx} tokens delivered in order across async clocks OK")
