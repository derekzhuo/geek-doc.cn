@echo off
cd /d %~dp0
echo %TIME% GUI_BAT_START >> progress.txt
start "" cmd /c "call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode gui -source gui.tcl > gui_vivado.log 2>&1"
set N=0
:retry
timeout /t 45 /nobreak > nul
powershell -NoProfile -Command "$ws=New-Object -ComObject wscript.shell; [void]$ws.AppActivate('Vivado 2017'); Start-Sleep 2"
powershell -NoProfile -ExecutionPolicy Bypass -File cap.ps1 -WindowTitle "Vivado 2017" -Out vivado-flow.png
if exist vivado-flow.png goto done
set /a N+=1
if %N% LSS 8 goto retry
:done
echo %TIME% CAP_DONE >> progress.txt
