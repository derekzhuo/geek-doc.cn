@echo off
cd /d "%~dp0"
set LTS=%LOCALAPPDATA%\Programs\ADI\LTspice\LTspice.exe
"%LTS%" -b mp2307_ripple.cir
if errorlevel 1 exit /b 1
"%LTS%" -b mp2307_load_step.cir
if errorlevel 1 exit /b 1
