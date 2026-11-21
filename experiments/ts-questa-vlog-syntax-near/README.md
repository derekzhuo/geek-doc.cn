# ts-questa-vlog-syntax-near

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-questa-vlog-syntax-near.html>（随对应教程上线后生效）

Questa Altera Starter FPGA Edition 2025.2 最小语法错误对照。`syntax_bad.v` 在 `led = 0` 后漏掉分号，编译器在下一行 `end` 处报告 `vlog-13069`；补回分号后同一工具链编译通过。

## 复现

```powershell
powershell -ExecutionPolicy Bypass -File run-questa.ps1 -Flow bad
powershell -ExecutionPolicy Bypass -File run-questa.ps1 -Flow good
```

工具路径在脚本顶部，按本机 Questa 安装位置修改。问题流程预期 `vlog` 返回 2，修复流程返回 0。

## 关键输出

```text
** Error: (vlog-13069) syntax_bad.v(7): near "end": syntax error, unexpected end, expecting ';'.
```

报错位置是解析器发现无法继续的位置，不一定是缺陷字符本身所在行。这里第 7 行的 `end` 合法，真正缺少的是第 6 行末尾的 `;`；`expecting ';'` 与上一行共同给出修复方向。

`err-vlog-syntax.log` 和 `fix-vlog-compile.log` 保留两次真实运行的规范化输出。
