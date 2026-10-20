# vivado-xsim-design-unit

Vivado XSim「找不到设计单元 / 快照不存在」排查实验：4 位计数器 + testbench，
分别复现 `ERROR: [XSIM 43-3225] Cannot find design unit`（xelab 顶层名写错）
与 `snapshot name ... does not exist`（没跑 xelab 直接 xsim）两类报错，再给出正确三连。

## 文件

- `counter4.v` —— 被测设计（DUT），异步复位 4 位计数器
- `tb_counter4.v` —— 测试平台，10ns 时钟 + `$monitor` 文本证据，`$finish` 收尾
- `run.bat` —— Windows 下一键 xvlog → xelab → xsim -R（改三个路径变量即可）
- `wave_setup.tcl` —— GUI 波形复现脚本：`add_wave` + `run all` + 改写 wcfg 全时间轴
- `out/` —— 写作当次的真实运行日志（报错与通过各一份）

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 触发一：xelab 顶层名写错（tb_counter 少个 4）→ XSIM 43-3225
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_counter -s sim_bad

rem 触发二：只 xvlog 不 xelab，直接 xsim → snapshot does not exist
D:\Xilinx\Vivado\2017.4\bin\xsim.bat work.tb_counter4 -R

rem 正确闭环
run.bat
```

GUI 波形：`xsim.bat sim_du -gui -tclbatch wave_setup.tcl`
