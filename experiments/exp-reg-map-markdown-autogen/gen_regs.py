#!/usr/bin/env python3
"""Markdown register table -> Verilog `define header + C header.

Input:  regs.md with a pipe table: name | offset | width | access | reset | description
Output: regs.vh (`define REG_<NAME>_ADDR / _MASK) and regs.h (#define ...)
Stdlib only.
"""
import re
import sys

def parse_md(path):
    regs = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("|"):
                continue
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) < 6:
                continue
            if cells[0].lower() == "name" or set(cells[0]) <= set("-: "):
                continue
            name, offset, width = cells[0], cells[1], cells[2]
            regs.append((name.upper(), int(offset, 0), int(width)))
    return regs

def mask(width):
    return (1 << width) - 1 if width < 32 else 0xFFFFFFFF

def emit_vh(regs, path):
    with open(path, "w", encoding="utf-8") as f:
        f.write("// AUTO-GENERATED from regs.md -- do not edit\n")
        f.write("`ifndef REGS_VH\n`define REGS_VH\n\n")
        for name, off, w in regs:
            f.write("`define REG_%s_ADDR 32'h%08X\n" % (name, off))
            f.write("`define REG_%s_MASK 32'h%08X\n" % (name, mask(w)))
        f.write("\n`endif\n")

def emit_h(regs, path):
    with open(path, "w", encoding="utf-8") as f:
        f.write("/* AUTO-GENERATED from regs.md -- do not edit */\n")
        f.write("#ifndef REGS_H\n#define REGS_H\n\n")
        for name, off, w in regs:
            f.write("#define REG_%s_ADDR (0x%08Xu)\n" % (name, off))
            f.write("#define REG_%s_MASK (0x%08Xu)\n" % (name, mask(w)))
        f.write("\n#endif\n")

def main():
    md, vh, h = sys.argv[1], sys.argv[2], sys.argv[3]
    regs = parse_md(md)
    if not regs:
        print("ERROR: no registers parsed from", md)
        sys.exit(1)
    emit_vh(regs, vh)
    emit_h(regs, h)
    print("parsed %d registers:" % len(regs))
    for name, off, w in regs:
        print("  %-10s offset=0x%02X width=%d" % (name, off, w))
    print("wrote", vh, "and", h)

if __name__ == "__main__":
    main()
