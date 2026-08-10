# Dotfiles Documentation Hub

이 서브 허브는 dotfiles 프로젝트의 세부 설계 문서, 가이드 및 플랫폼별 문서를 디아탁시스(Diátaxis) 4분면 체계로 안내합니다.

## 📂 디렉터리 구조

- `plans/`: 다중 호스트 Stow 패키지 구조 및 sops 암호화 설계/구현 계획 문서
- `desktop.md`: 데스크톱 가상화 및 GUI 환경 설정 문서
- `superpowers/`: AI 에이전트 내부 명세 및 작업 계획 (일반 문서 인덱스 제외)

---

## 🧭 Diátaxis 4분면 문서 인덱스

### 🟢 Tutorials (시작하기)
- [Root Install Guide](../README.md#install) - 호스트별 Stow 배포 및 패키지 설치
- [Windows Setup Guide](../windows/README.md) - Windows 환경 PowerShell 배포 및 테스트

### 🟡 How-To Guides (사용 및 조치)
- [Stow Adopt Guide](../README.md#stow-adopt) - 기존 dotfiles 패키지화 및 심볼릭 링크 전환
- [sops Key Encryption Plan](plans/2026-04-03-sops-key-encryption-implementation.md) - sops/age 암호화 키 적용 및 복호화 절차
- [NixOS Fcitx5 Setup](../nix/nixos/docs/fcitx5-wayland-kde.md) - NixOS KDE Wayland 환경 Fcitx5 한글 입력기 설정

### 🔵 Reference (참조 자료)
- [Main README](../README.md) - 메인 프로젝트 개요, 호스트/하드웨어 매트릭스 및 네트워크 구조
- [Neovim Configuration Guide](../base/.config/nvim/README.md) - lazy.nvim 기반 Neovim 모듈 구조 및 의존성
- [Neovim External Dependencies](../base/.config/nvim/DEPENDENCIES.md) - nvim 외부 도구 의존성

### 🟣 Explanation (설계 및 개념)
- [GNU Stow Structure Design](plans/2026-03-03-stow-structure-design.md) - multi-host Stow 패키지 레이아웃 설계 문서
- [sops Key Encryption Design](plans/2026-04-03-sops-key-encryption-design.md) - sops/age 기반 시크릿 관리 구조 설계 문서
- [Desktop Environment Spec](desktop.md) - 데스크톱 구성 요소 및 가상화 세부 설정
- [Neovim Design Specs](../base/.config/nvim/docs/plans/2026-03-03-cross-platform-neovim-design.md) - 크로스플랫폼 Neovim 모듈화 설계 명세
- [Neovim Implementation Plan](../base/.config/nvim/docs/plans/2026-03-03-cross-platform-neovim-implementation.md) - 크로스플랫폼 Neovim 구현 계획
