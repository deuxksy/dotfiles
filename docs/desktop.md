# Desktop Terminal Stack

> WezTerm + tmux + Neovim 통합 환경 문서

## 아키텍처

```mermaid
graph TB
    subgraph WezTerm["WezTerm (Terminal Emulator)"]
        direction TB
        W1["Font: Hack Nerd Font 13pt"]
        W2["Theme: Catppuccin Mocha"]
        W3["TERM=xterm-256color"]
        W4["Blur: 0.92 opacity"]
        W5["OSC 52 / Kitty Graphics"]
    end

    subgraph tmux["tmux (Multiplexer)"]
        direction TB
        T1["Prefix: Ctrl+A"]
        T2["default-terminal: tmux-256color"]
        T3["terminal-features<br/>RGB / clipboard / focus"]
        T4["is_vim smart switching"]
        T5["mouse on / set-clipboard on"]
    end

    subgraph Neovim["Neovim (Editor)"]
        direction TB
        N1["termguicolors=true"]
        N2["clipboard=unnamedplus"]
        N3["vim-tmux-navigator"]
        N4["FocusGained / VimResized"]
        N5["transparent_background"]
    end

    WezTerm -->|"spawn"| tmux
    tmux -->|"spawn"| Neovim

    style WezTerm fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
    style tmux fill:#1e1e2e,stroke:#94e2d5,color:#cdd6f4
    style Neovim fill:#1e1e2e,stroke:#f9e2af,color:#cdd6f4
```

## 레이어 책임

```mermaid
graph LR
    subgraph L1["Layer 1: Rendering"]
        W["WezTerm"]
    end

    subgraph L2["Layer 2: Session"]
        T["tmux"]
    end

    subgraph L3["Layer 3: Editing"]
        N["Neovim"]
    end

    L1 -->|"GPU 렌더링, 폰트, 색상"| L2
    L2 -->|"Pane/Tab, 세션 유지, 클립보드"| L3
```

| 레이어    | 담당          | 비고                                |
|-----------|---------------|-------------------------------------|
| WezTerm   | 렌더링 전담   | 폰트, 테마, 투명도, GPU 가속        |
| tmux      | Multiplexer   | Pane/Tab 분할, 세션 유지, SSH 복구  |
| Neovim    | 편집 전담     | LSP, Treesitter, Plugin 관리        |

## 키 입력 흐름

```mermaid
sequenceDiagram
    participant User
    participant WezTerm
    participant tmux
    participant Neovim

    Note over User,Neovim: Ctrl+H 입력 시

    User->>WezTerm: Ctrl+H
    WezTerm->>tmux: 전달 (TERM=xterm-256color)
    tmux->>tmux: is_vim 체크 (ps + grep nvim)

    alt nvim 실행 중
        tmux->>Neovim: Ctrl+H 전달
        Neovim->>Neovim: vim-tmux-navigator<br/>nvim split 존재?
        alt nvim split 있음
            Neovim->>Neovim: split 이동
        else nvim split 없음
            Neovim->>tmux: TmuxNavigateLeft<br/>(tmux select-pane -L)
            tmux->>tmux: 좌측 pane 이동
        end
    else nvim 미실행
        tmux->>tmux: select-pane -L<br/>(좌측 pane 이동)
    end
```

## 클립보드 흐름

```mermaid
sequenceDiagram
    participant User
    participant Neovim
    participant tmux
    participant WezTerm
    participant OS as OS Clipboard

    Note over User,OS: Neovim에서 yank 시

    User->>Neovim: yy (yank)
    Neovim->>Neovim: unnamedplus 레지스터
    Neovim->>tmux: OSC 52 이스케이프 시퀀스
    tmux->>tmux: set-clipboard on 처리
    tmux->>WezTerm: OSC 52 전달
    WezTerm->>OS: 시스템 클립보드 저장

    Note over User,OS: 반대 방향도 동일

    OS->>WezTerm: Cmd+C
    WezTerm->>tmux: 전달
    tmux->>Neovim: 전달
    Neovim->>Neovim: unnamedplus 레지스터에서 p (paste)
```

## 설정 파일 맵핑

```mermaid
graph TB
    subgraph ConfigFiles["설정 파일"]
        WT[".wezterm.lua"]
        TX[".tmux.conf"]
        NV["init.lua"]

        OPT["lua/core/options.lua"]
        KEY["lua/core/keymaps.lua"]
        AUC["lua/core/autocmds.lua"]
        THM["lua/plugins/theme.lua"]
        TMX["lua/plugins/tmux.lua"]
        TER["lua/plugins/terminal.lua"]
    end

    subgraph Stack["실행 스택"]
        W["WezTerm"]
        T["tmux"]
        N["Neovim"]
    end

    WT -->|"config_builder()"| W
    TX -->|"source-file"| T
    NV -->|"require"| OPT
    NV -->|"require"| KEY
    NV -->|"require"| AUC
    NV -->|"lazy.setup"| THM
    NV -->|"lazy.setup"| TMX
    NV -->|"lazy.setup"| TER

    OPT -->|"termguicolors<br/>clipboard<br/>mouse"| N
    KEY -->|"leader = Space"| N
    AUC -->|"FocusGained<br/>VimResized"| N
    THM -->|"monokai-pro<br/>transparent"| N
    TMX -->|"vim-tmux-navigator"| N

    style ConfigFiles fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
    style Stack fill:#1e1e2e,stroke:#a6e3a1,color:#cdd6f4
```

## 단축키 맵

```mermaid
graph LR
    subgraph WezTerm["WezTerm (리더키 없음)"]
        W_NONE["Leader 키 미사용<br/>tmux에 전담"]
    end

    subgraph tmux["tmux (Leader: Ctrl+A)"]
        direction TB
        TX["Leader → | : 수평 분할"]
        TX2["Leader → - : 수직 분할"]
        TX3["Leader → c : 새 Tab"]
        TX4["Leader → 1-9 : Tab 이동"]
        TX5["Leader → x : Pane 닫기"]
        TX6["Leader → z : Pane 확대"]
        TX7["Leader → [ : Copy mode"]
        TX8["Leader → s : Workspace"]
    end

    subgraph tmux_raw["tmux (Leader 없이)"]
        direction TB
        TR1["Ctrl+H/J/K/L<br/>is_vim 스마트 이동"]
    end

    subgraph Neovim["Neovim (Leader: Space)"]
        direction TB
        NV1["Ctrl+H/J/K/L<br/>vim-tmux-navigator"]
        NV2["Space + w/q/x<br/>저장/종료"]
        NV3["Space + bd/bn/bp<br/>버퍼 관리"]
        NV4["Space + tn/tc/to<br/>Tab 관리"]
        NV5["Space + t<br/>toggleterm"]
    end

    style WezTerm fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
    style tmux fill:#1e1e2e,stroke:#94e2d5,color:#cdd6f4
    style tmux_raw fill:#1e1e2e,stroke:#94e2d5,color:#cdd6f4
    style Neovim fill:#1e1e2e,stroke:#f9e2af,color:#cdd6f4
```

## 크로스 플랫폼 호환성

```mermaid
graph TB
    subgraph Platforms["플랫폼"]
        MAC["macOS"]
        FED["Fedora"]
        DEB["Debian"]
        ARCH["Arch"]
        NIX["NixOS"]
        WIN["Windows<br/>(WSL)"]
    end

    subgraph WezTermOpts["WezTerm macOS 전용"]
        M1["macos_window_background_blur"]
        M2["macos_forward_to_ime_modifier_mask"]
        M3["send_composed_key_when_*_alt"]
    end

    MAC -->|"적용"| M1
    MAC -->|"적용"| M2
    MAC -->|"적용"| M3

    FED -->|"자동 무시"| M1
    DEB -->|"자동 무시"| M1
    ARCH -->|"자동 무시"| M1
    NIX -->|"자동 무시"| M1
    WIN -->|"자동 무시"| M1

    subgraph Deps["Linux 필수 의존성"]
        D1["xclip (X11)"]
        D2["wl-clipboard (Wayland)"]
    end

    FED --> D1
    FED --> D2
    DEB --> D1
    DEB --> D2
    ARCH --> D1
    ARCH --> D2
    NIX --> D1
    NIX --> D2

    style Platforms fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
    style WezTermOpts fill:#1e1e2e,stroke:#f38ba8,color:#cdd6f4
    style Deps fill:#1e1e2e,stroke:#a6e3a1,color:#cdd6f4
```

| 플랫폼       | WezTerm | tmux | Neovim | 클립보드              | blur  |
|--------------|---------|------|--------|-----------------------|-------|
| macOS        | O       | O    | O      | pbcopy (내장)         | O     |
| Fedora       | O       | O    | O      | xclip / wl-clipboard  | comp  |
| Debian       | O       | O    | O      | xclip / wl-clipboard  | comp  |
| Arch         | O       | O    | O      | xclip / wl-clipboard  | comp  |
| NixOS        | O       | O    | O      | nix config에 추가     | comp  |
| Windows WSL  | O       | O    | O      | WSL clipboard         | X     |

> `comp` = compositor (picom, kwin, mutter 등) 필요

## TERM 설정 체인

```mermaid
graph LR
    subgraph Chain["TERM 전파"]
        W_TERM["WezTerm<br/>TERM=xterm-256color"]
        T_TERM["tmux<br/>default-terminal=tmux-256color"]
        N_TERM["Neovim<br/>termguicolors=true"]
    end

    W_TERM -->|"spawn"| T_TERM
    T_TERM -->|"terminal-features<br/>RGB/clipboard/focus"| N_TERM

    style Chain fill:#1e1e2e,stroke:#cba6f7,color:#cdd6f4
```

> `xterm-256color` 사용 이유: nix 환경에서 `wezterm` terminfo 미설치 시 에러 방지.
> tmux `terminal-features`로 True Color / OSC 52 / Focus event 보완.

## 파일 경로 요약

```
base/
├── .wezterm.lua                          # WezTerm 설정
├── .tmux.conf                            # tmux 설정
└── .config/nvim/
    ├── init.lua                          # Neovim 진입점
    └── lua/
        ├── core/
        │   ├── options.lua               # 기본 옵션 (clipboard, mouse, termguicolors)
        │   ├── keymaps.lua               # 키매핑 (leader=Space)
        │   └── autocmds.lua              # 자동명령 (FocusGained, VimResized)
        └── plugins/
            ├── theme.lua                 # monokai-pro (transparent_background)
            ├── tmux.lua                  # vim-tmux-navigator
            └── terminal.lua              # toggleterm
```
