import warnings

import cocotb
from cocotb.triggers import Timer
from cocotb.types import LogicArray


@cocotb.test()
async def logic_array_boundaries(dut):
    dut.data.value = LogicArray("00001010")
    await Timer(1, unit="ns")
    value = dut.data.value
    dut._log.info("resolved type=%s str=%s int=%d", type(value).__name__, str(value), int(value))
    assert str(value) == "00001010"
    assert int(value) == 10

    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        legacy_text = value.binstr
    assert legacy_text == "00001010"
    assert any(issubclass(item.category, DeprecationWarning) for item in caught)
    dut._log.info("binstr compatibility=%s warnings=%d", legacy_text, len(caught))

    dut.data.value = LogicArray("000010X1")
    await Timer(1, unit="ns")
    unresolved = dut.data.value
    dut._log.info("unresolved str=%s", str(unresolved))
    try:
        int(unresolved)
    except ValueError as exc:
        dut._log.info("int rejected: %s", exc)
    else:
        raise AssertionError("int() must reject X/Z values")
