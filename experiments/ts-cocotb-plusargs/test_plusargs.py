import os

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def read_two_channels(dut):
    await Timer(1, unit="ns")

    plusargs = dict(cocotb.plusargs)
    run_id = os.environ.get("RUN_ID")
    cocotb.log.info("cocotb.plusargs=%r", plusargs)
    cocotb.log.info("os.environ RUN_ID=%r", run_id)

    assert plusargs.get("MODE") == "fast", "missing simulator plusarg +MODE=fast"
    assert plusargs.get("REPEAT") == "3", "+REPEAT must arrive as the string '3'"
    assert plusargs.get("VERBOSE") is True, "a flag plusarg must have boolean value True"
    assert run_id == "env_42", "RUN_ID must be exported through the process environment"

    cocotb.log.info("both channels passed; REPEAT type=%s", type(plusargs["REPEAT"]).__name__)
