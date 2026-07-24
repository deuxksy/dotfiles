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

$wholeGeminiJunction = 'New-Item -ItemType Junction -Path "$env:USERPROFILE\.gemini"'
if ($scriptContent.Contains($wholeGeminiJunction)) {
    throw ".gemini 전체를 Junction으로 연결하면 안 됩니다"
}

Assert-Contains '$geminiDir = "$env:USERPROFILE\.gemini"' ".gemini 로컬 디렉토리 선언이 필요합니다"
Assert-Contains '$geminiDir\GEMINI.md' "GEMINI.md file symlink가 필요합니다"
Assert-Contains '$geminiDir\rules' "rules directory Junction이 필요합니다"
Assert-Contains '$geminiAntigravityDir\settings.json' "antigravity-cli/settings.json file symlink가 필요합니다"
Assert-Contains '[System.IO.FileAttributes]::ReparsePoint' "기존 .gemini Junction 충돌 검사가 필요합니다"

Write-Host "PASS: Gemini 설정이 부분 연결 구조를 사용합니다" -ForegroundColor Green
