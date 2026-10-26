@echo off
cd /d %~dp0
echo %TIME% BUILD_START > progress.txt
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_pass.tcl -tclargs loose -log vivado_loose.log -journal vivado_loose.jou
if exist vivado.log rename vivado.log vivado_loose_console.log
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_pass.tcl -tclargs tight -log vivado_tight.log -journal vivado_tight.jou
if exist vivado.log rename vivado.log vivado_tight_console.log
echo %TIME% BUILD_DONE >> progress.txt
