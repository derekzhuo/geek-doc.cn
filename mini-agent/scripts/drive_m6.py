#!/usr/bin/env python3
"""M6 驱动：两层权限防线的对照实录。

第一层是进程内策略：M5 的 PermissionPolicy 在工具分发前拒绝越权调用，
被拦的工具 handler 不会执行；第二层是操作系统沙箱：macOS 用
sandbox-exec（Seatbelt），等价的 Linux 方案是 bubblewrap（bwrap），
即使模型绕过工具层直接让子进程写文件，内核也会拒绝。

产物：traces/m6-policy.jsonl（策略层审计）与终端对照输出。只使用标准库。
"""

import json
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent.hooks import (  # noqa: E402
    AuditLog,
    HookedToolRegistry,
    PermissionPolicy,
)

SANDBOX_PROFILE = (
    '(version 1)(deny default)'
    '(allow process-exec)(allow process-fork)(allow signal)(allow sysctl-read)'
    '(allow file-read*)(allow ipc*)(allow mach-lookup)'
    '(allow file-write* (subpath "%(workspace)s"))'
    '(allow file-write* (subpath "/private/tmp"))'
    '(allow file-write* (subpath "/dev"))'
)


def reset_workspace():
    workspace = ROOT / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    workspace.mkdir(parents=True)
    (workspace / "task.txt").write_text("M6 沙箱演示工作区\n", encoding="utf-8")
    return workspace.resolve()


def policy_layer(workspace, audit_path):
    print("== 第一层：进程内权限策略（工具分发前拦截）==")
    if audit_path.exists():
        audit_path.unlink()
    registry = HookedToolRegistry(
        workspace,
        pre_hooks=[PermissionPolicy(modes={"run_test": "ask"})],
        post_hooks=[AuditLog(str(audit_path))])
    denied = registry.dispatch("run_test", {})
    print("策略 ask 下调用 run_test：ok=%s，原因：%s"
          % (denied.ok, denied.error["message"]))
    allowed = registry.dispatch("read_file", {"path": "task.txt"})
    print("同一会话读工作区文件：ok=%s，首行：%s"
          % (allowed.ok, allowed.content.splitlines()[0]))
    rows = [json.loads(line) for line in
            audit_path.read_text(encoding="utf-8").splitlines()]
    print("审计落盘 %d 条：%s"
          % (len(rows), " -> ".join(row["tool"] + "/" +
                                    ("ok" if row["ok"] else "denied")
                                    for row in rows)))
    print()


def os_layer(workspace):
    print("== 第二层：操作系统沙箱（内核拦截写操作）==")
    probe = ROOT / "scripts" / "m6_probe.py"
    print("-- 无沙箱基线 --")
    base = subprocess.run([sys.executable, str(probe), str(workspace)],
                          capture_output=True, text=True)
    print(base.stdout, end="")
    if platform.system() != "Darwin":
        print("当前平台无 sandbox-exec，OS 层对照跳过；"
              "Linux 等价命令：bwrap --ro-bind / / --bind %s %s --dev /dev --unshare-all ..."
              % (workspace, workspace))
        return
    profile = SANDBOX_PROFILE % {"workspace": str(workspace)}
    print("-- Seatbelt 沙箱内（deny default + 只放行工作区与临时目录写）--")
    boxed = subprocess.run(
        ["sandbox-exec", "-p", profile, sys.executable, str(probe),
         str(workspace)],
        capture_output=True, text=True)
    print(boxed.stdout, end="")
    if boxed.stderr.strip():
        print("stderr:", boxed.stderr.strip()[:200])


def main():
    workspace = reset_workspace()
    trace_dir = ROOT / "traces"
    trace_dir.mkdir(parents=True, exist_ok=True)
    policy_layer(workspace, trace_dir / "m6-policy.jsonl")
    os_layer(workspace)
    print("-" * 68)
    print("结论：策略层拦住「不该发起的工具调用」，沙箱层拦住「绕过工具层的"
          "子进程写」，两层失效模式独立，任一层被突破另一层仍在。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
