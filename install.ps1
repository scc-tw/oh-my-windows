$ErrorActionPreference = 'Stop'

# Self-elevate if not running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$scriptsDir = "$PSScriptRoot\scripts"
$scripts = Get-ChildItem -Path $scriptsDir -Filter '*.ps1' | Sort-Object Name

if ($scripts.Count -eq 0) {
    Write-Host "No scripts found in $scriptsDir" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "oh-my-windows installer" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  0) Run all" -ForegroundColor White

for ($i = 0; $i -lt $scripts.Count; $i++) {
    Write-Host "  $($i + 1)) $($scripts[$i].BaseName)" -ForegroundColor White
}

Write-Host ""
$input = Read-Host "Select an option (0-$($scripts.Count))"

if ($input -eq '0') {
    foreach ($s in $scripts) {
        Write-Host ""
        Write-Host ">>> $($s.BaseName)" -ForegroundColor Cyan
        & $s.FullName
    }
} elseif ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le $scripts.Count) {
    $selected = $scripts[[int]$input - 1]
    Write-Host ""
    Write-Host ">>> $($selected.BaseName)" -ForegroundColor Cyan
    & $selected.FullName
} else {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit 1
}
