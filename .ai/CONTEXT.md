# [CONTEXT] Infrastructure & Stow Architecture

## 0. 프로젝트 배경 및 목적 (Background & Purpose)

- **현황**: 현재 `ln -s` 수동 방식으로 인해 관리가 파편화되어 있음.
- **목표**: **GNU Stow** 체제로 전환하여 폴더 구조만으로 설정을 관리하는 직관적인 시스템 구축.
- **철학**: 15년 차 DevOps 엔지니어로서 "단순함"과 "관리의 투명성"을 최우선으로 함.

## 1. 대상 환경 (Target Infrastructure)

- **Mac Mini M4**: MacOS 26 (Apple Silicon)
- **AOOSTAR WTR R1**: Fedora 43 (RHEL 계열)
- **Steam Deck**: SteamOS 3.0 (Arch 계열)
- **Surface Pro 6**: Ubuntu 24 LTS (Debian 계열)

## 2. 핵심 설계 원칙: 라이브러리 4단계

1. **Layer 1 (Native PM)**: brew, apt, dnf, pacman 등 시스템에서 관리 및 실행.
2. **Layer 2 (MISE)**: Java, Node.js, Python, Rust, Lua 등 SDK 관리 및 실행.
3. **Layer 3 (On-demand)**: uvx, npx 등의 Package Runner 를 이용한 관리 및 실행.
4. **Layer 4 (Binary)**: `~/.local/bin` .

## 3. Migration Plan

- **Goal**: 기존 `ln -s` 수동 방식에서 GNU Stow 체제로 완전 전환.
