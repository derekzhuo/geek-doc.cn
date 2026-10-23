# vivado-set-property-empty：Vivado set_property 空对象复现

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-vivado-common-17-55-set-property.html（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-10-24；原始批处理输出见 `run.log`

## 复现方式

bad.xdc 里 get_ports 拼写错误（clck）拿到空对象（复现），good.xdc 正确拼写（对照）。Windows 下把 `vivado.bat`/`xvlog.bat` 全路径换成你的安装目录，按 run.log 里的命令序列逐条执行即可。

## 关键结论

空对象上 set_property 触发 `[Common 17-55]` 系列警告 ×8（2017.4 里是非致命警告，约束静默丢失——比报错更坑，时序约束根本没生效）。
