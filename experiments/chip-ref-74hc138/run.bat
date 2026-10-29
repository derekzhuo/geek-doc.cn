@echo off
echo # command: xvlog decoder.v tb.v ^&^& xelab tb -s snap ^&^& xsim snap -R
echo # date: 2026-10-30
echo # host-toolchain: Windows worker / Vivado XSim 2017.4
call D:\Xilinx\Vivado\2017.4\bin\xvlog.bat decoder.v tb.v
if errorlevel 1 exit /b 1
call D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb -s snap
if errorlevel 1 exit /b 1
call D:\Xilinx\Vivado\2017.4\bin\xsim.bat snap -R
set SIM_EXIT=%ERRORLEVEL%
if exist xsim.dir rmdir /s /q xsim.dir
if exist .Xil rmdir /s /q .Xil
del /q *.jou *.pb *.wdb webtalk*.log 2>nul
exit /b %SIM_EXIT%
