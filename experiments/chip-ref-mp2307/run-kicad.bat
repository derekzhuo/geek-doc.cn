@echo off
cd /d "%~dp0"
kicad-cli sch erc --output results\mp2307.rpt --severity-all mp2307.kicad_sch
if errorlevel 1 exit /b 1
type results\mp2307.rpt
