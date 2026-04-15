$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$crateDir = Join-Path $repoRoot 'confluence-cli'
$artifactDir = Join-Path $crateDir 'target\release'
$exe = Join-Path $artifactDir 'confluence.exe'

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
    if (-not ('Win32.ConfluenceCliInstallerNativeMethods' -as [type])) {
        Add-Type -Namespace Win32 -Name ConfluenceCliInstallerNativeMethods -MemberDefinition @"
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
    }

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x001A
    $SMTO_ABORTIFHUNG = 0x0002
    $result = [UIntPtr]::Zero

    [void][Win32.ConfluenceCliInstallerNativeMethods]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Environment',
        $SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    )
}

Write-Host "Building confluence-cli..." -ForegroundColor Cyan
cargo build --release --manifest-path "$crateDir\Cargo.toml"

if (-not (Test-Path $exe -PathType Leaf)) {
    throw "Expected build artifact not found: $exe"
}

$installDir = "$env:ProgramFiles\confluence-cli"
if (-not (Test-Path $installDir -PathType Container)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Copy-Item $exe -Destination $installDir -Force
Add-ToMachinePath -Target $installDir
Publish-EnvironmentChange

Write-Host "Installed confluence to $installDir" -ForegroundColor Green
Write-Host "Current binary is a scaffold for the Rust rewrite." -ForegroundColor Yellow
