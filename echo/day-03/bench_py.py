#!/usr/bin/env python3
# bench_py.py — Day 3 跨网络压测客户端（Python 版，功能等价 echo-kp-bench.c）
# 用途：在 macOS 本地 / Linux 服务器均可运行，实现 short / long 双模式，
#       用于子实验 3.4 跨网络部署对比（localhost vs 远程）。
# 背景：echo-kp-bench.c 依赖 pthread_barrier_t（Linux 特有），macOS 无法编译，
#       故用 threading.Barrier 重写，保证两端使用同一把尺子。
#
# Usage: python3 bench_py.py <ip> <port> <conns> <rounds> [--mode short|long]
# 输出：QPS / P50 / P90 / P99 / min / max（与 echo-kp-bench 相同的百分位口径）

import socket
import sys
import time
import threading

PAYLOAD = b"hello echo\r\n"   # 12 字节，与 echo-kp-bench 一致


def percentile(sorted_vals, n, p):
    if not sorted_vals:
        return 0
    idx = int(n * p)
    if idx < 0:
        idx = 0
    if idx >= n:
        idx = n - 1
    return sorted_vals[idx]


def do_short_round(ip, port, lat, idx):
    """短连接单轮：connect → send → recv → close，计时覆盖整轮 RTT"""
    t0 = time.perf_counter()
    fd = None
    try:
        fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        fd.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        fd.settimeout(30)
        fd.connect((ip, port))
        fd.sendall(PAYLOAD)
        got = b""
        while len(got) < len(PAYLOAD):
            chunk = fd.recv(4096)
            if not chunk:
                break
            got += chunk
        t1 = time.perf_counter()
        if got == PAYLOAD:
            lat[idx] = (t1 - t0) * 1e6
            return True
        return False
    except Exception:
        return False
    finally:
        if fd is not None:
            try:
                fd.close()
            except Exception:
                pass


def worker_short(ip, port, conn_id, rounds, lat, barrier, fail_counter):
    barrier.wait()
    for r in range(rounds):
        idx = conn_id * rounds + r
        if not do_short_round(ip, port, lat, idx):
            fail_counter[0] += 1
            lat[idx] = 0


def worker_long(ip, port, conn_id, rounds, lat, barrier, fail_counter):
    barrier.wait()
    fd = None
    try:
        fd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        fd.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        fd.settimeout(30)
        fd.connect((ip, port))
    except Exception:
        fail_counter[0] += rounds
        return

    for r in range(rounds):
        idx = conn_id * rounds + r
        t0 = time.perf_counter()
        try:
            fd.sendall(PAYLOAD)
            got = b""
            while len(got) < len(PAYLOAD):
                chunk = fd.recv(4096)
                if not chunk:
                    break
                got += chunk
            t1 = time.perf_counter()
            if got == PAYLOAD:
                lat[idx] = (t1 - t0) * 1e6
            else:
                fail_counter[0] += 1
                lat[idx] = 0
        except Exception:
            fail_counter[0] += 1
            lat[idx] = 0
    try:
        if fd is not None:
            fd.close()
    except Exception:
        pass


def main():
    if len(sys.argv) < 5:
        print("Usage: %s <ip> <port> <conns> <rounds> [--mode short|long]" % sys.argv[0])
        sys.exit(1)
    ip = sys.argv[1]
    port = int(sys.argv[2])
    conns = int(sys.argv[3])
    rounds = int(sys.argv[4])
    mode = "short"
    if "--mode" in sys.argv:
        mode = sys.argv[sys.argv.index("--mode") + 1]

    total_req = conns * rounds
    lat = [0.0] * total_req
    fail_counter = [0]
    barrier = threading.Barrier(conns + 1)
    threads = []

    t_start = time.perf_counter()
    for c in range(conns):
        if mode == "long":
            th = threading.Thread(target=worker_long,
                                  args=(ip, port, c, rounds, lat, barrier, fail_counter))
        else:
            th = threading.Thread(target=worker_short,
                                  args=(ip, port, c, rounds, lat, barrier, fail_counter))
        th.start()
        threads.append(th)

    barrier.wait()  # 主线程拉旗，所有工作线程同时开始
    for th in threads:
        th.join()
    elapsed = time.perf_counter() - t_start

    ok = total_req - fail_counter[0]
    qps = ok / elapsed if elapsed > 0 else 0.0

    vals = sorted([v for v in lat if v > 0])
    n = len(vals)
    print("bench_py | %s:%d | %d conns x %d rounds = %d reqs | mode=%s payload=%d" %
          (ip, port, conns, rounds, total_req, mode, len(PAYLOAD)))
    print("")
    print("=========== Results ===========")
    print(" requests:        %d / %d (ok:%d fail:%d)" % (total_req, total_req, ok, fail_counter[0]))
    print(" elapsed:         %.3f s" % elapsed)
    print(" QPS:             %.1f req/s" % qps)
    print(" latency (us) -----------------")
    if n > 0:
        print("  min:    %8.0f" % vals[0])
        print("  P50:    %8.0f" % percentile(vals, n, 0.50))
        print("  P90:    %8.0f" % percentile(vals, n, 0.90))
        print("  P99:    %8.0f" % percentile(vals, n, 0.99))
        print("  P999:   %8.0f" % percentile(vals, n, 0.999))
        print("  max:    %8.0f" % vals[-1])
        print("  count:  %8d" % n)
    print("===============================")


if __name__ == "__main__":
    main()
