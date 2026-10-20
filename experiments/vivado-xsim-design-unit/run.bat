@echo off
rem Vivado XSim 批处理最小闭环：xvlog -> xelab -> xsim -R
rem 用法：把 XVLOG/XELAB/XSIM 三个路径改成本机 Vivado 安装目录
set XVLOG=D:\Xilinx\Vivado\2017.4\bin\xvlog.bat
set XELAB=D:\Xilinx\Vivado\2017.4\bin\xelab.bat
set XSIM=D:\Xilinx\Vivado\2017.4\bin\xsim.bat

call %XVLOG% counter4.v tb_counter4.v || exit /b 1
call %XELAB% -debug typical tb_counter4 -s sim_du || exit /b 1
call %XSIM% sim_du -R || exit /b 1
