# 常用芯片最小接线原理图（chip-ref-wiring）

**对应教程**：<https://geek-doc.cn/chip-design/chip-ref/>

这组实验用 KiCad 10 建立常用芯片与模块的最小可运行接线：逻辑器件展示地址、时钟和片选连接，电源器件展示输入、反馈、电感和电容网络，MCU 与模块展示电源、复位、启动、下载和一个示范外设。原理图不依赖私有库，生成时会把 KiCad 标准库符号嵌入 `.kicad_sch`，在装有 KiCad 10 的机器上可直接打开、ERC 检查和导出 SVG。当前仓库内 14 份 ERC 报告均为 `0 Errors / 0 Warnings`。

## 目录

- `circuits/`：每个芯片一份 JSON 接线规格，描述元件、脚号和网络标签。
- `generate.mjs`：读取 KiCad 标准符号库并生成自包含 `.kicad_sch`。
- `kicad/`：生成的 KiCad 原理图。
- `reports/`：KiCad CLI 的 ERC 报告。
- `svg/`：KiCad CLI 导出的 SVG 图纸。
- `windows/`：Windows 11 + KiCad 10 per-user 安装下的批处理和 Edge 预览脚本。

## 依赖

- Node.js 20。
- KiCad 10，需要标准符号库和 `kicad-cli`。
- Windows per-user 默认路径：
  - `%LOCALAPPDATA%\Programs\KiCad\10.0\bin`
  - `%LOCALAPPDATA%\Programs\KiCad\10.0\share\kicad\symbols`

## 检查接线规格

```bash
node validate-specs.mjs
```

该检查只验证 JSON 结构、元件引用、重复连接和电源标记；真实符号脚号与 ERC 仍以 KiCad CLI 的结果为准。

## 生成原理图

PowerShell：

```powershell
$env:KICAD_SYMBOL_DIR = "$env:LOCALAPPDATA\Programs\KiCad\10.0\share\kicad\symbols"
node generate.mjs
```

也可以只生成一份：

```powershell
$env:KICAD_SYMBOL_DIR = "$env:LOCALAPPDATA\Programs\KiCad\10.0\share\kicad\symbols"
$env:CIRCUIT_FILE = "circuits\ne555.json"
$env:OUTPUT_FILE = "kicad\ne555.kicad_sch"
node generate.mjs
```

## 升级、ERC 与导出 SVG

```powershell
.\windows\validate-kicad.bat
```

脚本依次执行格式升级、SVG 导出和 ERC。每份图纸的 ERC 报告写入 `reports/<slug>.rpt`，SVG 写入 `svg/<slug>.svg`。验收时报告应显示 `0 Errors` 和 `0 Warnings`。

## 在浏览器中查看完整图纸

某些 Windows 会话中的原理图编辑器画布可能无法正常显示图元，但 `kicad-cli` 生成的 SVG 不受影响。可用 Edge 打开导出的 SVG：

```powershell
.\windows\launch-svg.bat "%CD%\svg\ne555.svg"
```

脚本使用独立浏览器配置目录，关闭预览时执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\cleanup-edge.ps1
```

需要连续查看全部图纸时，用 `capture-svg.ps1` 串行打开 SVG，避免多个浏览器窗口同时抢占前台：

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\capture-svg.ps1
```

## MAX485 符号说明

KiCad 标准库中的 `MAX485E` 继承 `LTC2850xS8` 的 SOIC-8 图形和引脚定义，派生层只更新元件属性。为了让自动生成的缓存符号保持单一、可复现，`circuits/max485.json` 使用非继承的 `Interface_UART:LTC2850xS8` 图形，实例 Value 仍标注为 `MAX485`；网络连接按 MAX485 的 1–8 脚定义生成。

## 接线规格怎么读

JSON 中每一个 link 都是“元件脚号 → 网络名”。同名网络即电气连接，例如所有 `GND` 引脚属于同一网络，不需要在图纸上画一根穿越整页的长线。未连接脚放在 `no_connect` 中，KiCad 会显示叉号，避免 ERC 把有意悬空的输入脚当成遗漏。

修改接线时优先改 `circuits/*.json`，再重新运行生成和校验脚本；不要直接手改 `kicad/` 里的产物。
