@echo off
setlocal
set "SVG=%~1"
if "%SVG%"=="" exit /b 1
set "SVG_URL=file:///%SVG:\=/%"
start "" msedge.exe --app="%SVG_URL%" --user-data-dir="%~dp0edge-profile" --no-first-run
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0focus-edge.ps1" -Pattern "%~n1"
exit /b %errorlevel%
