import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer


async def reset_dut(dut, duration_ns: float = 4.0):
    dut.rst_n_i.value = 0
    await Timer(duration_ns, units="ns")
    dut.rst_n_i.value = 1
    await Timer(duration_ns, units="ns")
    dut._log.info("Reset released")


async def init_dut(dut, duration_ns: float = 4.0):
    dut.a_i.value = 0
    dut.b_i.value = 0
    dut.is_signed_i.value = 0
    await Timer(duration_ns, units="ns")
    dut._log.info("Initialized DUT")


def test_multiplier(dut, a: int, b: int, signed: bool = False):
    dut.a_i.value = a
    dut.b_i.value = b
    dut.is_signed_i.value = signed


@cocotb.test()
async def mul_i16_0x0(dut):
    """multiple test: 0x0"""

    a = 0
    b = 0

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()
async def mul_i16_0x1(dut):
    """multiple test: 0x1"""

    a = 0
    b = 1

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()
async def mul_i16_1x0(dut):
    """multiple test: 1x0"""

    a = 1
    b = 0

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut._log.info(f"a is {a}")
    dut._log.info(f"b is {b}")
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()  # type: ignore
async def mul_i16_1x1(dut):
    """multiple test: 1x1"""

    a = 1
    b = 1

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut._log.info(f"a is {a}")
    dut._log.info(f"b is {b}")
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()  # type: ignore
async def mul_i16_1x2(dut):
    """multiple test: 1x2"""

    a = 1
    b = 2

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut._log.info(f"a is {a}")
    dut._log.info(f"b is {b}")
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()  # type: ignore
async def mul_i16_2x1(dut):
    """multiple test: 2x1"""

    a = 2
    b = 1

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut.data_vld_i.value = 1
    dut._log.info(f"a is {a}")
    dut._log.info(f"b is {b}")
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %s", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()  # type: ignore
async def mul_i16_max(dut):
    """multiple test: max"""

    a = 2**16 - 1
    b = 2**16 - 1

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
    dut._log.info(f"a is {a}")
    dut._log.info(f"b is {b}")
    dut.data_vld_i.value = 1
    test_multiplier(dut, a, b)
    dut.data_vld_i.value = 0
    await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

    dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
    dut._log.info("c_o is %d", dut.c_o.value)
    assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"


@cocotb.test()  # type: ignore
async def mul_i16_unsigned_random(dut):
    """multiple test: random unsigned values"""

    # random.seed(cocotb.RANDOM_SEED)
    a = random.randint(0, 2**16 - 1)
    b = random.randint(0, 2**16 - 1)

    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    await RisingEdge(dut.clk_i)  # wait for rising edge/"posedge"
    await init_dut(dut)
    await reset_dut(dut)

    for i in range(100):
        await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
        dut._log.info(f"a is {a}")
        dut._log.info(f"b is {b}")
        dut.data_vld_i.value = 1
        test_multiplier(dut, a, b)
        dut.data_vld_i.value = 0
        await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"

        dut._log.info("data_vld_o is %s", dut.data_vld_o.value)
        dut._log.info("c_o is %d", dut.c_o.value)
        assert dut.c_o.value == (a * b), f"c_o is not {a*b}!"
        await FallingEdge(dut.clk_i)  # wait for falling edge/"negedge"
