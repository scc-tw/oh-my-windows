$ErrorActionPreference = 'Stop'

$taskName = 'bear generates a compilation database for Clang tooling'
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$crateDir = "$repoRoot\bear"
$artifactDir = Join-Path $crateDir 'target\release'
$driverExe = Join-Path $artifactDir 'bear-driver.exe'
$wrapperExe = Join-Path $artifactDir 'bear-wrapper.exe'

function Test-PathEntry {
    param(
        [string]$PathValue,
        [string]$Target
    )

    $normalizedTarget = [Environment]::ExpandEnvironmentVariables($Target).Trim().Trim('"').TrimEnd('\')
    foreach ($entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $normalizedEntry = [Environment]::ExpandEnvironmentVariables($entry).Trim().Trim('"').TrimEnd('\')
        if ($normalizedEntry.Equals($normalizedTarget, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Add-ToMachinePath {
    param([string]$Target)

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not (Test-PathEntry -PathValue $machinePath -Target $Target)) {
        $updatedMachinePath = if ([string]::IsNullOrWhiteSpace($machinePath)) {
            $Target
        } else {
            "$machinePath;$Target"
        }

        [Environment]::SetEnvironmentVariable('Path', $updatedMachinePath, 'Machine')
        Write-Host "Added $Target to the machine PATH" -ForegroundColor Green
    } else {
        Write-Host "$Target is already in the machine PATH" -ForegroundColor DarkGray
    }

    if (-not (Test-PathEntry -PathValue $env:Path -Target $Target)) {
        $env:Path = if ([string]::IsNullOrWhiteSpace($env:Path)) {
            $Target
        } else {
            "$env:Path;$Target"
        }
    }
}

function Publish-EnvironmentChange {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern System.IntPtr SendMessageTimeout(
    System.IntPtr hWnd,
    uint Msg,
    System.UIntPtr wParam,
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out System.UIntPtr lpdwResult);
"@

    $HWND_BROADCAST   = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x001A
    $SMTO_ABORTIFHUNG = 0x0002
    $result = [UIntPtr]::Zero

    [void][Win32.NativeMethods]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Environment',
        $SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    )
}

# Build
Write-Host "Building bear..." -ForegroundColor Cyan
cargo build --release --manifest-path "$crateDir\Cargo.toml"

# Install to a location in PATH.
# Keep bear-driver and bear-wrapper as siblings because Bear resolves the wrapper
# using a relative path from the driver executable at runtime.
$installDir = "$env:ProgramFiles\bear"
$runtimeBinDir = Join-Path $installDir 'libexec\bear\bin'
$launcher = Join-Path $installDir 'bear.cmd'

foreach ($dir in @($installDir, $runtimeBinDir)) {
    if (-Not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

foreach ($artifact in @($driverExe, $wrapperExe)) {
    if (-Not (Test-Path $artifact)) {
        throw "Expected build artifact not found: $artifact"
    }
}

Copy-Item $driverExe -Destination $runtimeBinDir -Force
Copy-Item $wrapperExe -Destination $runtimeBinDir -Force

$driverPath = Join-Path $runtimeBinDir 'bear-driver.exe'
$launcherContent = @"
@echo off
"%~dp0libexec\bear\bin\bear-driver.exe" %*
"@
Set-Content -Path $launcher -Value $launcherContent -NoNewline

Add-ToMachinePath -Target $installDir
Publish-EnvironmentChange

Write-Host "Installed bear to $installDir" -ForegroundColor Green
