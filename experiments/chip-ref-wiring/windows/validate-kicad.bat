@echo off
setlocal
cd /d "%~dp0.."

if not defined KICAD_BIN set "KICAD_BIN=%LOCALAPPDATA%\Programs\KiCad\10.0\bin"
if not defined KICAD_SYMBOL_DIR set "KICAD_SYMBOL_DIR=%LOCALAPPDATA%\Programs\KiCad\10.0\share\kicad\symbols"

if not exist kicad mkdir kicad
if not exist reports mkdir reports
if not exist svg mkdir svg

node generate.mjs
if errorlevel 1 exit /b 1

for %%S in (kicad\*.kicad_sch) do call :process "%%S" "%%~nS"
exit /b 0

:process
set "SCH=%~1"
set "NAME=%~2"
"%KICAD_BIN%\kicad-cli.exe" sch upgrade --force "%SCH%"
if errorlevel 1 exit /b 2
"%KICAD_BIN%\kicad-cli.exe" sch export svg --output "svg" "%SCH%"
if errorlevel 1 exit /b 3
"%KICAD_BIN%\kicad-cli.exe" sch erc --output "reports\%NAME%.rpt" --severity-all "%SCH%"
if errorlevel 1 exit /b 4
goto :eof
