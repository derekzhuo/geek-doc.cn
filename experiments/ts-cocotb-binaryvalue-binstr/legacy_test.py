import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Timer


@cocotb.test()
async def legacy_binary_string(dut):
    dut.data.value = BinaryValue(0, n_bits=8, binaryString="00001010")
    await Timer(1, unit="ns")
    dut._log.info("legacy binstr=%s", dut.data.value.binstr)
