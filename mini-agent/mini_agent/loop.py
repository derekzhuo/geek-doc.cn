"""agent loop 主循环——M1 的全部核心，约 50 行。

一轮循环只做三件事：
1. 把完整消息历史交给模型，拿回一条 assistant 消息；
2. 没有工具调用 = 任务结束，返回最终文本；
3. 有工具调用 = 逐个执行，把每条结果以 tool 角色追加进历史，继续下一轮。

模型只负责「决定做什么」，工具只负责「把事做掉并如实汇报」，
loop 不做任何业务判断——这就是 coding agent 与聊天机器人的分界线。
"""


def run_loop(model, tools, messages, tracer, max_steps=8, reporter=None,
             context_window=None):
    tracer.event("session_start", max_steps=max_steps)
    for step in range(max_steps):
        tracer.event("step_begin", step=step)
        if context_window is not None:  # M3：模型调用前先做窗口治理
            context_window.before_model_call(messages, tracer, step)
        reply = model.complete(messages)  # ① 模型决策
        messages.append(reply)
        tracer.message(reply)
        if reporter:
            reporter("assistant", reply)

        calls = reply.get("tool_calls")
        if not calls:  # ② 无工具调用：终止
            tracer.event("session_end", reason="final_answer", steps=step + 1)
            return reply["content"]

        parallel = len(calls) > 1 and all(tools.is_readonly(call["name"]) for call in calls)
        if parallel:
            tracer.event("tool_batch", mode="parallel", size=len(calls))
        for call in calls:
            tracer.event("tool_call", id=call["id"], name=call["name"])
        results = tools.dispatch_many(calls)  # ③ 只读批次可并发，结果仍按请求序回流
        for call, result in zip(calls, results):
            message = {
                "role": "tool",
                "content": result.content,
                "tool_call_id": call["id"],
            }
            if result.error is not None:
                message["error"] = result.error
            messages.append(message)
            tracer.message(message)
            tracer.event("tool_result", id=call["id"], ok=result.ok)
            if reporter:
                reporter("tool", call, result)

    tracer.event("session_end", reason="max_steps_exceeded", steps=max_steps)
    raise RuntimeError("超过最大步数 %d 仍未结束" % max_steps)
