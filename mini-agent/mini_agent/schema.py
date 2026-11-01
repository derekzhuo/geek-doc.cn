"""mini-agent 使用的 JSON Schema 子集校验器。

只实现工具参数真正用到的关键字：type/properties/required/
additionalProperties/default/minimum/maximum/minLength。它不是通用
JSON Schema 库，但刻意保留熟悉的声明形状，便于替换为完整实现。
"""

import copy
import json


class SchemaError(ValueError):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


_TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
}


def parse_and_validate(arguments, schema):
    """解析 JSON 字符串或复制 dict，再返回补全默认值后的参数。"""
    if isinstance(arguments, str):
        try:
            arguments = json.loads(arguments)
        except json.JSONDecodeError as exc:
            raise SchemaError("invalid_json", "arguments 不是合法 JSON: %s" % exc.msg)
    if not isinstance(arguments, dict):
        raise SchemaError("schema_validation", "arguments 必须是 JSON object")

    values = copy.deepcopy(arguments)
    properties = schema.get("properties", {})
    for key, spec in properties.items():
        if key not in values and "default" in spec:
            values[key] = copy.deepcopy(spec["default"])

    missing = [key for key in schema.get("required", []) if key not in values]
    if missing:
        raise SchemaError("schema_validation", "缺少必填参数: %s" % ", ".join(missing))
    if schema.get("additionalProperties") is False:
        extra = sorted(set(values) - set(properties))
        if extra:
            raise SchemaError("schema_validation", "存在未声明参数: %s" % ", ".join(extra))

    for key, value in values.items():
        spec = properties.get(key)
        if spec is None:
            continue
        expected = _TYPES[spec["type"]]
        # Python 的 bool 是 int 子类，但 JSON Schema 中两者不是同一种类型。
        if spec["type"] in ("integer", "number") and isinstance(value, bool):
            raise SchemaError("schema_validation", "参数 %s 应为 %s" % (key, spec["type"]))
        if not isinstance(value, expected):
            raise SchemaError("schema_validation", "参数 %s 应为 %s" % (key, spec["type"]))
        if "minimum" in spec and value < spec["minimum"]:
            raise SchemaError("schema_validation", "参数 %s 不能小于 %s" % (key, spec["minimum"]))
        if "maximum" in spec and value > spec["maximum"]:
            raise SchemaError("schema_validation", "参数 %s 不能大于 %s" % (key, spec["maximum"]))
        if "minLength" in spec and len(value) < spec["minLength"]:
            raise SchemaError("schema_validation", "参数 %s 不能为空字符串" % key)
    return values
