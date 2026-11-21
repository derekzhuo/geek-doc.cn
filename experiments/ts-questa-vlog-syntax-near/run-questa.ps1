param([ValidateSet('bad', 'good')][string]$Flow = 'bad')
$bin = 'D:\altera_lite\25.1std\questa_fse\win64'
& "$bin\vlib.exe" work
& "$bin\vmap.exe" work work
& "$bin\vlog.exe" "syntax_$Flow.v"
exit $LASTEXITCODE
