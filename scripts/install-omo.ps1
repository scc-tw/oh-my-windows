$ErrorActionPreference = 'Stop'

param(
    [ValidateSet('no', 'yes', 'max20')]
    [string]$Claude = 'no',

    [ValidateSet('no', 'yes')]
    [string]$OpenAI = 'yes',

    [ValidateSet('no', 'yes')]
    [string]$Gemini = 'no',

    [ValidateSet('no', 'yes')]
    [string]$Copilot = 'no',

    [switch]$SkipAuth = $true,

    [switch]$InstallCommentChecker
)

if (-not (Get-Command bunx -ErrorAction SilentlyContinue)) {
    throw "bunx is required. Install bun first, for example via scripts/install-scoop.ps1."
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    throw "OpenCode is required. Install opencode first, for example via scripts/install-scoop.ps1."
}

$arguments = @(
    'oh-my-opencode'
    'install'
    '--no-tui'
    "--claude=$Claude"
    "--openai=$OpenAI"
    "--gemini=$Gemini"
    "--copilot=$Copilot"
)

if ($SkipAuth) {
    $arguments += '--skip-auth'
}

Write-Host "Installing oh-my-openagent..." -ForegroundColor Cyan
& bunx @arguments

if ($InstallCommentChecker) {
    Write-Host "Installing optional comment-checker..." -ForegroundColor Cyan
    npm install -g @code-yeongyu/comment-checker
}

Write-Host "Running oh-my-openagent doctor..." -ForegroundColor Cyan
& bunx oh-my-opencode doctor

Write-Host "oh-my-openagent install complete." -ForegroundColor Green
Write-Host "Tip: start with 'opencode' and include 'ultrawork' in your prompt." -ForegroundColor DarkGray
