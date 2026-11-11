"""消息结构：agent loop 里流转的全部对象都是普通 dict。

一条消息的角色（role）有四种：
- system：系统指令，定义 agent 的行为边界；
- user：用户任务；
- assistant：模型回复，content 为文本，tool_calls 为请求执行的工具调用；
- tool：工具执行结果，通过 tool_call_id 与 assistant 的调用一一对应。

用 dict 而不是自定义类，是为了和主流 function calling API 的 JSON 结构
保持同构：M2 接真实模型时，消息可以直接序列化发出去。
"""


def system_msg(content):
    return {"role": "system", "content": content}


def user_msg(content):
    return {"role": "user", "content": content}


def assistant_msg(content="", tool_calls=None):
    msg = {"role": "assistant", "content": content}
    if tool_calls:
        msg["tool_calls"] = tool_calls
    return msg


def tool_msg(call_id, content):
    return {"role": "tool", "content": content, "tool_call_id": call_id}


def tool_call(call_id, name, arguments):
    """构造一条工具调用请求。"""
    return {"id": call_id, "name": name, "arguments": arguments}
