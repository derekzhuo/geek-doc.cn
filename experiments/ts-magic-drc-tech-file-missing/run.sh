#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 Magic 8.3）" >&2
  exit 2
fi
run() {
  docker run --rm -i -v "$PWD:/work" -w /work "$IMAGE" \
    magic -noconsole -dnull -T "$1" < probe.tcl 2>&1
}

printf -- "--- 1. 请求不存在的工艺：回退 minimum，规则为 0，但退出码仍为 0 ---\n$ magic -noconsole -dnull -T definitely_missing < probe.tcl\n"
run definitely_missing
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 使用镜像内置 scmos：加载 155 条 tech 规则 ---\n$ magic -noconsole -dnull -T scmos < probe.tcl\n"
run scmos
printf -- "RC=%s\n" "$?"
