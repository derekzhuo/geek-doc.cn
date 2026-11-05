# openlane-wsl-path-issue：Docker bind mount 盘符路径报错复现

**对应教程**：<https://geek-doc.cn/eda/ts-openlane-wsl-path-issue.html>（上线后生效）

## 环境

- Docker 29.1.3 / Ubuntu 22.04（Linux docker 主机；WSL2 + Docker Desktop 同理）
- 日期：2026-11-06；原始输出见 `wsl-path.log`

## 复现

```bash
./run.sh
```

- case1：`-v 'C:\Users\dev\proj:/data'`，daemon 把反斜杠后的 `:/data` 解析成挂载模式，报 `invalid mode: /data`，exit 125。
- case2：`-v 'C:/Users/dev/proj:/data'`，正斜杠盘符路径同样不是合法 Linux 路径，报同样的错，exit 125。
- case3：`-v /tmp/wsl-mount-demo:/data`（WSL2 下用 `wslpath -a 'C:\Users\dev\proj'` 换成 `/mnt/c/...`），挂载成功，容器内可见 `/data`，exit 0。

## 文件

- `run.sh`：三组对照脚本，镜像可用 `IMG=... ./run.sh` 覆盖。
- `wsl-path.log`：真机原始日志（含三行头与每轮 exit code）。
