param([ValidateSet('bad', 'good')][string]$Flow = 'bad')
$bin = 'D:\altera_lite\25.1std\quartus\bin64'
$compile = if ($Flow -eq 'bad') { 'compile_bad.tcl' } else { 'compile_good.tcl' }
$sta = if ($Flow -eq 'bad') { 'sta_bad.tcl' } else { 'sta_good.tcl' }
& "$bin\quartus_sh.exe" -t $compile 2>&1 | Tee-Object -FilePath "$Flow-compile.log"
& "$bin\quartus_sta.exe" -t $sta 2>&1 | Tee-Object -FilePath "$Flow-sta.log"
exit $LASTEXITCODE
