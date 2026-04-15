$ErrorActionPreference = 'Stop'

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    throw "Scoop is required. Run scripts/install-scoop.ps1 first."
}

$extrasBucket = scoop bucket list | Select-String '^\s*extras\s'
if (-not $extrasBucket) {
    Write-Host "Adding Scoop bucket 'extras'..." -ForegroundColor Cyan
    scoop bucket add extras
}

$installed = scoop list | Select-String '^\s*jira-cli\s'
if ($installed) {
    Write-Host "jira-cli already installed via Scoop." -ForegroundColor Green
} else {
    Write-Host "Installing jira-cli via Scoop..." -ForegroundColor Cyan
    scoop install jira-cli
}

Write-Host "jira-cli install complete." -ForegroundColor Green
Write-Host "Login flow:" -ForegroundColor Cyan
Write-Host "  1. Set your token: `$env:JIRA_API_TOKEN = 'your-api-token'" -ForegroundColor DarkGray
Write-Host "  2. Initialize cloud Jira:" -ForegroundColor DarkGray
Write-Host "     jira init --installation cloud --server https://your-domain.atlassian.net --login you@example.com" -ForegroundColor DarkGray
Write-Host "  3. Verify with: jira me" -ForegroundColor DarkGray
