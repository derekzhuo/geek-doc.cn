param(
    [ValidateSet('bad', 'good')][string]$Flow = 'bad'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# bad  -> flow_bad.tcl, expected to fail with Error (10028) multiple constant drivers, exit code nonzero
# good -> flow_good.tcl, expected "Full Compilation was successful", exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
$tcl = if ($Flow -eq 'bad') { 'flow_bad.tcl' } else { 'flow_good.tcl' }
$log = if ($Flow -eq 'bad') { 'err-10028-multi-driver.log' } else { 'fix-compile-pass.log' }

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
