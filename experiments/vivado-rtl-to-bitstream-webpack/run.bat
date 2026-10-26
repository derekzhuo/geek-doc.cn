@echo off
cd /d %~dp0
echo %TIME% BUILD_START > progress.txt
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source build.tcl -log vivado_build.log -journal vivado_build.jou
echo %TIME% BUILD_DONE >> progress.txt
