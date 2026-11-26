#!/usr/bin/env python3
"""Generate exhaustive ALU expectations from integer arithmetic, not RTL."""

from pathlib import Path

MASK = 0xF
ROOT = Path(__file__).resolve().parent


def signed4(value):
    return value - 16 if value >= 8 else value


def arithmetic(a, b, total, no_borrow=None):
    result = total & MASK
    carry = int(total > MASK) if no_borrow is None else int(no_borrow)
    mathematical = signed4(a) + signed4(b) if no_borrow is None else signed4(a) - signed4(b)
    overflow = int(not -8 <= mathematical <= 7)
    return result, carry, overflow


def add(a, b):
    return arithmetic(a, b, a + b)


def sub(a, b):
    return arithmetic(a, b, a - b, no_borrow=a >= b)


def logic(a, b, result):
    return result & MASK, 0, 0


OPERATIONS = (
    ("ADD", add),
    ("SUB", sub),
    ("AND", lambda a, b: logic(a, b, a & b)),
    ("OR", lambda a, b: logic(a, b, a | b)),
    ("XOR", lambda a, b: logic(a, b, a ^ b)),
)


def vector(op, a, b):
    name, function = OPERATIONS[op]
    result, carry, overflow = function(a, b)
    negative = (result >> 3) & 1
    zero = int(result == 0)
    return op, a, b, result, negative, zero, carry, overflow


def format_vector(fields):
    return "{:x} {:x} {:x} {:x} {:d} {:d} {:d} {:d}".format(*fields)


def main():
    vectors = [vector(op, a, b)
               for op in range(len(OPERATIONS))
               for a in range(16)
               for b in range(16)]
    assert len(vectors) == len(OPERATIONS) * 16 * 16 == 1280
    (ROOT / "vectors.txt").write_text(
        "\n".join(format_vector(item) for item in vectors) + "\n",
        encoding="ascii",
    )

    selected = [
        (0, 7, 1),
        (0, 15, 1),
        (1, 0, 0),
        (1, 0, 1),
        (1, 7, 15),
        (2, 15, 10),
    ]
    (ROOT / "wave_vectors.txt").write_text(
        "\n".join(format_vector(vector(*item)) for item in selected) + "\n",
        encoding="ascii",
    )

    print("REFERENCE=integer arithmetic and bitwise operations; no RTL case reuse")
    print("OPERATIONS=" + ",".join(f"{op}:{name}" for op, (name, _) in enumerate(OPERATIONS)))
    print(f"VECTORS={len(vectors)} (5 operations x 16 A values x 16 B values)")
    print("SUB_C=1 means no unsigned borrow; this is the experiment's local convention")
    for item in selected:
        fields = vector(*item)
        print("SPOT " + format_vector(fields) + " " + OPERATIONS[item[0]][0])
    boundary_spots = [(0, 8, 8), (1, 8, 1), (1, 7, 8), (2, 0, 15), (4, 15, 15)]
    for item in boundary_spots:
        fields = vector(*item)
        print("BOUNDARY " + format_vector(fields) + " " + OPERATIONS[item[0]][0])
    print("GENERATOR SELF-CHECK PASS: count=1280, selected=6, boundary_spots=5")


if __name__ == "__main__":
    main()
