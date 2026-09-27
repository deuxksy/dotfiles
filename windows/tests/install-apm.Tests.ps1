$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "install.ps1"
$scriptContent = Get-Content $scriptPath -Raw

function Assert-Contains {
    param([string]$Expected, [string]$Message)
    if (-not $scriptContent.Contains($Expected)) { throw $Message }
}

Assert-Contains '-Target "$dotfiles\base\.apm\apm.yml"' "apm manifest는 base 패키지를 가리켜야 합니다 (windows 중복 금지)"
Assert-Contains '-Target "$dotfiles\base\.apm\apm.lock.yaml"' "apm lock은 base 패키지를 가리켜야 합니다"
Assert-Contains '-Target "$dotfiles\base\.claude\settings.json"' "settings.json은 base 고정 파일을 가리켜야 합니다"
Assert-Contains '-Target "$dotfiles\base\.config\claude"' "provider profiles 디렉터리는 base를 가리켜야 합니다"
Assert-Contains 'apm install -g' "apm install -g 단계가 있어야 합니다"
Assert-Contains 'Microsoft.APM' "apm CLI는 winget Microsoft.APM으로 설치해야 합니다"

Assert-Contains 'settings.json.bak-' "kyolim 기존 settings.json은 백업 후 링크해야 합니다"

Write-Host "install-apm tests passed"
