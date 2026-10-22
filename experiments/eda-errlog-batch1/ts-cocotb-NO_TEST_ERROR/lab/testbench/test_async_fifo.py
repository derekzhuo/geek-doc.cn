import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


async def reset_dut(dut):
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wdata.value = 0
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0
    await Timer(50, unit="ns")
    dut.wrst_n.value = 1
    dut.rrst_n.value = 1
    await Timer(50, unit="ns")


@cocotb.test()
async def single_write_read(dut):
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 13, unit="ns").start())
    await reset_dut(dut)

    token = 0xA5
    await FallingEdge(dut.wclk)
    dut.wdata.value = token
    dut.wr_en.value = 1
    await FallingEdge(dut.wclk)
    dut.wr_en.value = 0

    for _ in range(10):
        await RisingEdge(dut.rclk)
    await FallingEdge(dut.rclk)
    dut.rd_en.value = 1
    await RisingEdge(dut.rclk)
    await FallingEdge(dut.rclk)
    dut.rd_en.value = 0
    got = int(dut.rdata.value)
    assert got == token, f"expect {token:#x}, got {got:#x}"
    dut._log.info("single token %#x delivered across async clocks OK", token)


@cocotb.test()
async def random_back_to_back(dut):
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 13, unit="ns").start())
    await reset_dut(dut)

    rng = random.Random(20261021)
    total = 200
    tokens = [rng.randrange(256) for _ in range(total)]
    received = []

    async def writer():
        sent = 0
        await RisingEdge(dut.wclk)
        while sent < total:
            await FallingEdge(dut.wclk)
            if not int(dut.full.value) and rng.random() < 0.7:
                dut.wdata.value = tokens[sent]
                dut.wr_en.value = 1
                sent += 1
            else:
                dut.wr_en.value = 0

    async def reader():
        armed = False
        while len(received) < total:
            await FallingEdge(dut.rclk)
            if armed:
                received.append(int(dut.rdata.value))
                armed = False
            if not int(dut.empty.value) and rng.random() < 0.6:
                dut.rd_en.value = 1
                armed = True
            else:
                dut.rd_en.value = 0

    await cocotb.start(writer())
    await cocotb.start(reader())
    while len(received) < total:
        await RisingEdge(dut.rclk)

    assert received == tokens, "FIFO delivered tokens out of order"
    dut._log.info("%d tokens delivered in order across async clocks OK", total)
