param(
  [string]$SvgDir = (Join-Path $PSScriptRoot '..\svg'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\shots')
)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$profileDir = Join-Path $PSScriptRoot 'edge-profile'

function Stop-EdgeProfile {
  Get-CimInstance Win32_Process -Filter "Name = 'msedge.exe'" |
    Where-Object { $_.CommandLine -like "*$profileDir*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

foreach ($svg in Get-ChildItem -Path $SvgDir -Filter '*.svg' | Sort-Object Name) {
  Stop-EdgeProfile
  Start-Sleep -Milliseconds 500

  $uri = 'file:///' + $svg.FullName.Replace('\', '/')
  $outFile = Join-Path $OutDir ("$($svg.BaseName).png")
  if (Test-Path $outFile) { Remove-Item $outFile -Force }

  Start-Process 'msedge.exe' -Wait -ArgumentList @(
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    '--disable-extensions',
    "--user-data-dir=$profileDir",
    '--window-size=1536,960',
    "--screenshot=$outFile",
    $uri
  )

  if (!(Test-Path $outFile)) { throw "Edge screenshot failed for $($svg.Name)" }
  Write-Output "captured $outFile"
}

Stop-EdgeProfile
exit 0
