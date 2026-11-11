#!/usr/bin/env python3
"""通过 UNIX 域套接字连 QMP，读取整机状态与 vCPU 拓扑后优雅退出。"""
import json
import socket
import sys

sock_path = sys.argv[1] if len(sys.argv) > 1 else "qmp.sock"
s = socket.socket(socket.AF_UNIX)
s.connect(sock_path)
print(s.recv(4096).decode().splitlines()[0][:80])


def cmd(c):
    s.sendall((json.dumps(c) + "\n").encode())
    return s.recv(8192).decode().strip()


print(cmd({"execute": "qmp_capabilities"}))
print(cmd({"execute": "query-status"}))
print(cmd({"execute": "query-cpus-fast"}))
print(cmd({"execute": "quit"}))
