param(
  [Parameter(Mandatory=$true)][string]$Pattern
)

Start-Sleep -Seconds 5
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32EdgeFit {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

$proc = Get-Process msedge -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowTitle -like "*$Pattern*" } |
  Select-Object -First 1
if ($null -eq $proc) { exit 2 }

[void][Win32EdgeFit]::ShowWindow($proc.MainWindowHandle, 3)
Start-Sleep -Milliseconds 800
[void][Win32EdgeFit]::SetForegroundWindow($proc.MainWindowHandle)
Start-Sleep -Milliseconds 800

$ws = New-Object -ComObject WScript.Shell
[void]$ws.AppActivate($proc.Id)
Start-Sleep -Milliseconds 500
for ($i = 0; $i -lt 4; $i++) {
  $ws.SendKeys('^-')
  Start-Sleep -Milliseconds 400
}
exit 0
