"""JSONL trace：loop 每一步都往 trace 文件追加一行事件。

每行是一个独立 JSON 对象，带 seq 序号，内容分两类：
- type="message"：一条真正进入消息历史的消息（assistant / tool）；
- type="event"：生命周期事件（session_start / session_end）。

JSONL（每行一个 JSON）而不是整个大 JSON 数组，是为了长任务可以
tail -f 实时观察，也方便中途崩溃时保留已发生的现场。
"""

import json


class Tracer(object):
    def __init__(self, path):
        self.path = path
        self._seq = 0
        self._fh = open(path, "w", encoding="utf-8")

    def _write(self, record):
        self._seq += 1
        record["seq"] = self._seq
        self._fh.write(json.dumps(record, ensure_ascii=False) + "\n")
        self._fh.flush()

    def event(self, kind, **payload):
        self._write({"type": "event", "event": kind, "payload": payload})

    def message(self, message):
        self._write({"type": "message", "message": message})

    def close(self):
        self._fh.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.close()
