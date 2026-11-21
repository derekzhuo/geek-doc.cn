param([ValidateSet('nosdc', 'realistic')][string]$Flow = 'nosdc')
$bin = 'D:\altera_lite\25.1std\quartus\bin64'
$compile = "compile_$Flow.tcl"
$sta = "sta_$Flow.tcl"
& "$bin\quartus_sh.exe" -t $compile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& "$bin\quartus_sta.exe" -t $sta
exit $LASTEXITCODE
