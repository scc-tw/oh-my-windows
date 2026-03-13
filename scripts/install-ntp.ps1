$ErrorActionPreference = 'Stop'

$taskName = 'NTP Force Sync'
$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$crateDir = "$repoRoot\ntp"
$exe = "$crateDir\target\release\ntp.exe"

# Build
Write-Host "Building ntp..." -ForegroundColor Cyan
cargo build --release --manifest-path "$crateDir\Cargo.toml"

# Remove existing scheduled task if present
$existing = schtasks /query /tn $taskName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Removing existing task '$taskName'..." -ForegroundColor Yellow
}

# Create (or overwrite) scheduled task — /f forces overwrite
schtasks /create /tn $taskName /tr $exe /sc onstart /ru SYSTEM /rl HIGHEST /f
Write-Host "Scheduled task '$taskName' -> $exe" -ForegroundColor Green

# Run it now
Write-Host "Running NTP sync now..." -ForegroundColor Cyan
& $exe
