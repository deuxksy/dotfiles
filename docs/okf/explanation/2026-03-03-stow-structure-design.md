# Stow 구조 설계

**날짜**: 2026-03-03
**상태**: 승인 완료
**최종 수정**: 2026-03-09

## 1. 개요

GNU Stow를 활용한 다중 플랫폼 dotfiles 관리 구조 재설계.

## 2. 패키지 구조

```
env/
├── base/              # 공통 설정 (모든 장비)
│   ├── .zshrc
│   ├── .vimrc
│   └── .gitconfig
│
├── eve/               # macOS (Mac Mini M4)
│   ├── .ssh/config
│   ├── .zshrc
│   ├── .vimrc
│   ├── .path
│   ├── .alias
│   ├── .function.sh
│   ├── .netrc.example
│   ├── .bashrc
│   └── .profile
│   # 제외: .crush/, .ansible/, Brewfile, .key
│
├── walle/             # AOOSTAR WTR R1 (Fedora NAS)
│   └── .alias
│
├── girl/              # Steam Deck
│   ├── .alias
│   └── Brewfile
│
├── old/               # 백업 (Stow 제외)
└── nvim/              # Neovim (교차 플랫폼)
```

## 3. Stow 적용 방법

### Mac Mini M4 (eve)
```bash
stow -t ~ base
stow -t ~ eve
```

### AOOSTAR WTR R1 (walle)
```bash
stow -t ~ base
stow -t ~ walle
```

### Steam Deck (girl)
```bash
stow -t ~ base
stow -t ~ girl
```

### Neovim (모든 플랫폼)
```bash
stow -t ~ nvim
```

## 4. 제외 항목 (.stow-local-ignore)

| 패키지 | 제외 항목 | 이유 |
|--------|----------|------|
| eve | .crush, .ansible, Brewfile, .key | 개인 도구, 비밀정보 |
| girl | Brewfile | 원 위치 유지 |
| old | 전체 | 백업용 |

## 5. 보안

- `.key` 파일은 `.gitignore`에 포함되어 Git 추적 제외
- 민감 정보가 포함된 파일은 수동 관리 권장
