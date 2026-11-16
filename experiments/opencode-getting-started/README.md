# OpenCode 接入国产模型并完成一次真实改码任务

**对应教程**：https://geek-doc.cn/ai-tools/agent-compare/opencode-getting-started-cn.html （随站点发布生效）

在本机从零安装 OpenCode CLI，把火山方舟 Coding Plan 的 Anthropic 兼容端点接成自定义 provider，
然后在一个带真实缺陷的 C 小项目上用 headless 模式（`opencode run`）完成修 bug 与补测试，
全程原始对话与工具调用留痕。

## 目录结构

| 文件 | 作用 |
|---|---|
| `demo/buggy-stats.c` | 任务起点：含除零与整数截断两个缺陷的 C 程序，复现时复制为 `stats.c` |
| `demo/README.md` | 交给 agent 的问题说明 |
| `demo/opencode.json` | 自定义 provider 配置示例，密钥走环境变量 `ARK_CODING_KEY`，不入库 |
| `results/stats-fixed.c` | agent 实际改出的修复版源码 |
| `results/test.sh` | agent 新写的三用例测试脚本 |
| `results/run1.log` | 一次完整 `opencode run` 的原始终端记录（安装版本、改码、跑测试） |

## 复现方式

```bash
# 1. 安装（npm 上的包名是 opencode-ai，不是 opencode）
npm install -g opencode-ai
# 若提示 postinstall script was not run，手动补一次：
cd "$(npm root -g)/opencode-ai" && node postinstall.mjs
opencode --version

# 2. 准备实验项目
mkdir oc-demo && cd oc-demo
cp <本目录>/demo/buggy-stats.c stats.c
cp <本目录>/demo/README.md .
cp <本目录>/demo/opencode.json .
export ARK_CODING_KEY=你的方舟 Coding Plan API Key

# 3. headless 跑任务
opencode run "修复 stats.c 的除零与整数截断缺陷，并新增 test.sh 覆盖正常、单元素、空序列三组用例"

# 4. 独立验证（不要只看 agent 自述）
./test.sh
printf '1 2 -1' | ./stats    # 期望 avg=1.50
printf -- '-1' | ./stats     # 期望 avg=0.00
```

## 接入要点与三个高频坑

1. **包名是 `opencode-ai`**：`npm i opencode` 会 404，二进制命令才叫 `opencode`。
2. **postinstall 可能被跳过**：全局 npm 配置忽略安装脚本时，`opencode` 只报
   “postinstall script was not run”，按提示进包目录手动 `node postinstall.mjs` 即可。
3. **Anthropic 兼容端点的 baseURL 要带 `/v1`**：OpenCode 的 anthropic provider 会在
   baseURL 后直接拼 `/messages`，只填到 `/api/coding` 会打到错误路径，表现为 401
   Unauthorized；正确写法是 `https://ark.cn-beijing.volces.com/api/coding/v1`。
4. 密钥不要写进 `opencode.json`，用 `{env:ARK_CODING_KEY}` 引用环境变量。

## 测量口径

- 任务成功与否以独立运行 `test.sh` 的退出码和手工边界用例为准，不采信 agent 自述；
- `results/run1.log` 为单次真实会话原文，未做内容润色；不同账号、不同模型版本下
  agent 的具体措辞和 diff 会不同，但修复点与测试覆盖可对照。
