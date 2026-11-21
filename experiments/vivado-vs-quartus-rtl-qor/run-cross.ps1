$ErrorActionPreference = 'Stop'
$vivado = 'D:\Xilinx\Vivado\2017.4\bin\vivado.bat'
$quartus = 'D:\altera_lite\25.1std\quartus\bin64'
Set-Location $PSScriptRoot
Remove-Item -Recurse -Force .Xil,work,results -ErrorAction SilentlyContinue
Remove-Item -Force cross-results.zip -ErrorAction SilentlyContinue

& cmd /c "`"$vivado`" -mode batch -log vivado.log -source vivado_qor.tcl > vivado-console.log 2>&1"
$vivadoRc = $LASTEXITCODE
if ($vivadoRc -ne 0 -and (Select-String -Path vivado.log -Pattern 'couldn''t read file|rt-undefined' -Quiet)) {
    Copy-Item vivado.log vivado.log.retry -Force
    Copy-Item vivado-console.log vivado-console.log.retry -Force
    & cmd /c "`"$vivado`" -mode batch -log vivado.log -source vivado_qor.tcl > vivado-console.log 2>&1"
    $vivadoRc = $LASTEXITCODE
}
if ($vivadoRc -ne 0) { Get-Content vivado-console.log; throw "Vivado failed with rc=$vivadoRc" }
if ((Select-String -Path vivado.log -Pattern '^VIVADO_QOR_RESULT ').Count -ne 1) { throw 'Missing Vivado QoR marker' }

& cmd /c "`"$quartus\quartus_sh.exe`" -t quartus_compile.tcl > quartus-compile.log 2>&1"
if ($LASTEXITCODE -ne 0) { Get-Content quartus-compile.log; throw "Quartus compile failed with rc=$LASTEXITCODE" }
& cmd /c "`"$quartus\quartus_sta.exe`" -t quartus_sta.tcl > quartus-sta.log 2>&1"
if ($LASTEXITCODE -ne 0) { Get-Content quartus-sta.log; throw "Quartus STA failed with rc=$LASTEXITCODE" }
if ((Select-String -Path quartus-sta.log -Pattern '^QUARTUS_QOR_RESULT ').Count -ne 1) { throw 'Missing Quartus QoR marker' }

New-Item -ItemType Directory -Force results | Out-Null
Copy-Item vivado.log,quartus-compile.log,quartus-sta.log results/
Copy-Item work/vivado/utilization.rpt results/vivado-utilization.rpt
Copy-Item work/vivado/timing.rpt results/vivado-timing.rpt
Copy-Item work/quartus/fifo_cross.map.summary results/quartus-map.summary
Copy-Item work/quartus/fifo_cross.fit.summary results/quartus-fit.summary
Compress-Archive -Path results/* -DestinationPath cross-results.zip -Force
Write-Output 'CROSS_TOOL_QOR_OK'
