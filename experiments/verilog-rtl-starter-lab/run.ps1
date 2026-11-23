# Windows entry point: run all five labs without requiring make.
# Usage:  .\run.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$labs = @(
  "lab01-clock-divider",
  "lab02-debounce",
  "lab03-seq-detector-fsm",
  "lab04-uart-tx",
  "lab05-sync-fifo"
)

$fail = 0
foreach ($lab in $labs) {
  Write-Host "=== $lab ==="
  New-Item -ItemType Directory -Force -Path "$lab/sim_build" | Out-Null
  $sources = @(Get-ChildItem "$lab/tb/*.v") + @(Get-ChildItem "$lab/rtl/*.v")
  iverilog -g2005 -I common -o "$lab/sim_build/sim.vvp" $sources
  if ($LASTEXITCODE -ne 0) { $fail = 1; continue }
  vvp "$lab/sim_build/sim.vvp"
  if ($LASTEXITCODE -ne 0) { $fail = 1 }
}

if ($fail -eq 0) {
  Write-Host "RESULT: PASS 5/5"
} else {
  Write-Host "RESULT: FAIL"
  exit 1
}
