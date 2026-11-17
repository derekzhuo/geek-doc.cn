@echo off
cd /d %~dp0
set LTS=
if exist "%LOCALAPPDATA%\Programs\ADI\LTspice\LTspice.exe" set LTS=%LOCALAPPDATA%\Programs\ADI\LTspice\LTspice.exe
if "%LTS%"=="" if exist "C:\Program Files\ADI\LTspice\LTspice.exe" set LTS=C:\Program Files\ADI\LTspice\LTspice.exe
if "%LTS%"=="" (
  echo LTspice not found. Edit run.bat with your LTspice.exe path.
  exit /b 1
)
"%LTS%" -b ams1117_dropout.cir
if errorlevel 1 exit /b 1
"%LTS%" -b ams1117_loadtrans.cir
