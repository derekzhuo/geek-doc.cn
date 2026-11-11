param(
    [Parameter(Mandatory = $true)][string]$Tcl,
    [Parameter(Mandatory = $true)][string]$Log
)
# Vivado 2017.4 batch back-to-back runs can hit a stale helper-process
# shm/handle lock ("couldn't read file .../rt/data/...tcl: No error").
# Settle 30s up front; retry once only on that environmental signature.
# Semantic synth errors (Synth/DRC codes) are never retried.
$vivado = "D:\Xilinx\Vivado\2017.4\bin\vivado.bat"
taskkill /F /IM vivado.exe 2>$null
Start-Sleep -Seconds 30
Remove-Item -Recurse -Force .Xil -ErrorAction SilentlyContinue

cmd /c "`"$vivado`" -mode batch -source $Tcl 2>&1" | Tee-Object -FilePath $Log
if (Select-String -Path $Log -Pattern "couldn't read file" -Quiet) {
    Write-Output "ENV_RETRY: helper lock detected, rerun after 30s"
    taskkill /F /IM vivado.exe 2>$null
    Start-Sleep -Seconds 30
    Remove-Item -Recurse -Force .Xil -ErrorAction SilentlyContinue
    cmd /c "`"$vivado`" -mode batch -source $Tcl 2>&1" | Tee-Object -FilePath $Log
}
