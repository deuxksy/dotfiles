$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "install.ps1"
$scriptContent = Get-Content $scriptPath -Raw

function Assert-Contains {
    param(
        [string]$Expected,
        [string]$Message
    )

    if (-not $scriptContent.Contains($Expected)) {
        throw $Message
    }
}

Assert-Contains '-Target "$dotfiles\windows\.claude\settings.local.json"' "글로벌 settings.local.json은 windows 패키지를 가리켜야 합니다"

$baseTarget = '-Target "$base\.claude\settings.local.json"'
if ($scriptContent.Contains($baseTarget)) {
    throw "글로벌 settings.local.json이 base를 가리키면 안 됩니다"
}

Write-Host "PASS: 글로벌 settings.local.json이 windows 패키지를 사용합니다" -ForegroundColor Green
