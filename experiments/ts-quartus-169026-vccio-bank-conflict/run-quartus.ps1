param(
    [ValidateSet('bad', 'good')][string]$Flow = 'bad'
)
# Quartus Prime Lite 25.1 command-line full compile wrapper.
# bad  -> flow_bad.tcl, led_b assigned 3.0-V LVTTL in the same bank as 3.3V pins:
#         Fitter Error (169026) VCCIO incompatibility, exit code nonzero
# good -> flow_good.tcl, all four pins 3.3-V LVTTL: full compile succeeds, exit code 0
$quartusSh = "D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe"
$tcl = if ($Flow -eq 'bad') { 'flow_bad.tcl' } else { 'flow_good.tcl' }
$log = if ($Flow -eq 'bad') { 'err-169026-vccio-conflict.log' } else { 'fix-compile-pass.log' }

& $quartusSh -t $tcl 2>&1 | Tee-Object -FilePath $log
exit $LASTEXITCODE
