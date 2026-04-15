$ErrorActionPreference = 'Stop'

# Install scoop if not present
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing scoop..." -ForegroundColor Cyan
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
} else {
    Write-Host "Scoop already installed." -ForegroundColor Green
}

# Buckets
$buckets = @(
    @{ name = 'extras' }
    @{ name = 'psmux'; url = 'https://github.com/psmux/scoop-psmux' }
)

Write-Host "Adding buckets..." -ForegroundColor Cyan
foreach ($bucket in $buckets) {
    $existing = scoop bucket list | Select-String "^\s*$($bucket.name)\s"
    if ($existing) {
        Write-Host "  Bucket '$($bucket.name)' already added." -ForegroundColor Gray
    } elseif ($bucket.url) {
        scoop bucket add $bucket.name $bucket.url
    } else {
        scoop bucket add $bucket.name
    }
}

# Packages to install
$packages = @(
    # main bucket
    '7zip'
    'bun'
    'cmake'
    'dark'
    'gettext'
    'gh'
    'git'
    'glab'
    'innounp'
    'llvm'
    'neovim'
    'nodejs-lts'
    'opencode'
    'poetry'
    'python'
    'rust'
    'rustup'
    'sed'
    'tokei'
    'uv'

    # extras bucket
    'jira-cli'
    'keepass'
    'mattermost'
    'obs-studio'
    'sysinternals'
    'vesktop'

    # psmux bucket
    'psmux'
)

Write-Host "Installing packages..." -ForegroundColor Cyan
foreach ($pkg in $packages) {
    $installed = scoop list | Select-String "^\s*$pkg\s"
    if ($installed) {
        Write-Host "  $pkg already installed." -ForegroundColor Gray
    } else {
        Write-Host "  Installing $pkg..." -ForegroundColor Yellow
        scoop install $pkg
    }
}

Write-Host "Scoop setup complete." -ForegroundColor Green
