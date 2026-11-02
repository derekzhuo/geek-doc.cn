# filelist.f —— 编译清单：一行一个源文件，# 开头为注释
# 顺序随意，iverilog 全量扫描后按模块依赖自行确定编译顺序
rtl/alu.v
rtl/regfile.v
rtl/datapath.v
tb/tb_top.v
