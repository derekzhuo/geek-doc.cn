#!/usr/bin/env python3
"""M6 沙箱探针：尝试写工作区内文件与工作区外的 /etc，如实汇报结果。

退出码不参与判定，两种写入各自的成功/失败结果打印成结构化行，
由 drive_m6.py 在沙箱内外各跑一次后对照。
"""

import os
import sys
import tempfile
from pathlib import Path

workspace = Path(sys.argv[1])
targets = [
    ("workspace", workspace / "sandbox_probe.txt"),
    ("home", Path.home() / "mini-agent-m6-probe.txt"),
    ("etc", Path("/etc/mini-agent-m6-probe.txt")),
    ("tmp", Path(tempfile.gettempdir()) / "mini-agent-m6-probe.txt"),
]
for label, target in targets:
    try:
        target.write_text("probe from mini-agent M6\n", encoding="utf-8")
        print("write %s: ALLOWED %s" % (label, target))
    except OSError as exc:
        print("write %s: DENIED %s (%s)" % (label, target, exc.__class__.__name__))
    finally:
        if label in ("workspace", "home", "tmp") and target.exists():
            target.unlink()
sys.exit(0)
