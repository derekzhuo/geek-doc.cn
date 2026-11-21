param([ValidateSet('baseline', 'setup_only', 'paired')][string]$Flow = 'baseline')
$bin = 'D:\altera_lite\25.1std\quartus\bin64'
if (-not (Test-Path 'multicycle_demo.qsf')) {
    & "$bin\quartus_sh.exe" -t compile.tcl
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& "$bin\quartus_sta.exe" -t "sta_$Flow.tcl"
exit $LASTEXITCODE
