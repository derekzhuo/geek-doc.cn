#!/usr/bin/env python3
"""Minimal loopback Responses API fixture for deterministic Codex CLI tests."""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

port_file, command_file = sys.argv[1:3]


def event(name, payload):
    return f"event: {name}\ndata: {json.dumps(payload, separators=(',', ':'))}\n\n".encode()


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        request = json.loads(self.rfile.read(length) or b"{}")
        if not self.path.endswith("/responses"):
            self.send_error(404)
            return

        prior_items = request.get("input", [])
        tool_outputs = [
            item.get("output") for item in prior_items
            if isinstance(item, dict) and item.get("type") == "function_call_output"
        ]
        if tool_outputs:
            with open(command_file + ".outputs.jsonl", "a", encoding="utf-8") as f:
                f.write(json.dumps(tool_outputs, ensure_ascii=False) + "\n")
        has_tool_output = bool(tool_outputs)
        response_id = f"resp_fixture_{int(time.time() * 1000)}"
        if has_tool_output:
            item = {
                "id": "msg_fixture",
                "type": "message",
                "status": "completed",
                "role": "assistant",
                "content": [{"type": "output_text", "text": "fixture command finished", "annotations": []}],
            }
        else:
            with open(command_file, encoding="utf-8") as f:
                command = json.load(f)["command"]
            item = {
                "id": "fc_fixture",
                "type": "function_call",
                "call_id": "call_fixture",
                "name": "exec_command",
                "arguments": json.dumps({"cmd": command, "yield_time_ms": 1000, "max_output_tokens": 2000, "sandbox_permissions": "require_escalated", "justification": "Verify the selected approval policy with a disposable probe."}, separators=(",", ":")),
            }

        response = {
            "id": response_id,
            "object": "response",
            "created_at": int(time.time()),
            "status": "completed",
            "model": "fixture-model",
            "output": [item],
            "usage": {"input_tokens": 1, "output_tokens": 1, "total_tokens": 2},
        }
        body = event("response.output_item.done", {
            "type": "response.output_item.done", "output_index": 0, "item": item
        }) + event("response.completed", {
            "type": "response.completed", "response": response
        })
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
with open(port_file, "w", encoding="utf-8") as f:
    f.write(str(server.server_port))
server.serve_forever()
