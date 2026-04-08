# Windows Dotfiles Setup

## 사전 요구사항

### 필수 도구
- [mise](https://github.com/jdx/mise) - 런타임 버전 관리
- [Neovim](https://neovim.io/) - 텍스트 에디터
- [Git](https://git-scm.com/) - 버전 관리

### mise로 Node.js 설치
```powershell
mise use node@lts
```

### pnpm 활성화 (corepack 사용)
```powershell
corepack enable
corepack prepare pnpm@latest --activate
pnpm setup
```

### mcp-hub 설치
```powershell
pnpm install -g mcp-hub@latest
```

## 환경변수 설정

Neovim 플러그인(MCP Hub, CodeCompanion 등)에서 사용하는 API Key를 환경변수로 등록합니다.

```powershell
# User scope 환경변수 등록
$apiKey = "YOUR_API_KEY_HERE"
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
[System.Environment]::SetEnvironmentVariable("ZAI_API_KEY", $apiKey, "User")
[System.Environment]::SetEnvironmentVariable("BRAVE_API_KEY", $apiKey, "User")
[System.Environment]::SetEnvironmentVariable("CONTEXT7_API_KEY", $apiKey, "User")
```

> 환경변수 등록 후 **터미널을 재시작**해야 적용됩니다.

## 설치 (install.ps1)

### 관리자 권한으로 실행
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\git\dotfiles\windows\install.ps1"
```

### 스크립트가 수행하는 작업

| 대상 경로 | 원본 (base) | 방식 | 권한 |
|---|---|---|---|
| `%LOCALAPPDATA%\nvim` | `base\.config\nvim` | Junction | 일반 |
| `%USERPROFILE%\.claude` | `base\.claude` | Junction | 일반 |
| `%USERPROFILE%\.gemini` | `base\.gemini` | Junction | 일반 |
| `%USERPROFILE%\.gitconfig` | `base\.gitconfig` | SymbolicLink | 관리자 |
| `%USERPROFILE%\.wakatime.cfg` | `base\.wakatime.cfg` | SymbolicLink | 관리자 |
| `%USERPROFILE%\.wezterm.lua` | `base\.wezterm.lua` | SymbolicLink | 관리자 |

## Neovim 초기 실행

설치 후 Neovim을 실행하면 Lazy.nvim이 자동으로 플러그인을 설치합니다.

```powershell
nvim
```

첫 실행 시 `:Lazy sync`를 수동으로 실행하면 모든 플러그인이 설치됩니다.

## 주의사항

- 파일 심볼릭 링크(`SymbolicLink`)는 **관리자 권한**이 필요합니다
- 디렉토리 Junction은 관리자 권한 없이 생성 가능합니다
- 설정 파일 원본은 `base/` 폴더에 있으며, `windows/` 폴더에는 설치 스크립트만 있습니다
- Windows에서 Developer Mode를 활성화하면 관리자 권한 없이도 심볼릭 링크 생성이 가능합니다
