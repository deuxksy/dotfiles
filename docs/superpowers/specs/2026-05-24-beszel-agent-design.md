# beszel-agent NixOS 설계

> **Date**: 2026-05-24
> **Host**: mo (NixOS workstation)
> **Hub**: heritage.bun-bull.ts.net (다른 Tailscale 머신)

## 목표

beszel-agent를 NixOS 선언적 설정으로 배포하여 mo 서버 모니터링 활성화.

## 파일 구조

- `nix/nixos/hosts/mo/beszel.nix` — beszel-agent 서비스 정의 (신규)
- `nix/nixos/hosts/mo/default.nix` — imports에 `./beszel.nix` 추가

## 설정

```text
services.beszel.agent.enable      = true
services.beszel.agent.openFirewall = true
services.beszel.agent.environment:
  LISTEN  = "45876"
  KEY     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo8CE9Y7ZScOXSEIOshSjYNTsHjp0vZ9XEuDQI59vSs"
  TOKEN   = "96f03983-0ece-41f3-97bc-74be4fcf9398"
  HUB_URL = "https://heritage.bun-bull.ts.net/beszel"
```

## 설계 결정

| 항목 | 결정 | 이유 |
| :--- | :--- | :--- |
| sops 암호화 | 미사용 | 사용자 명시적 선택 (beszel은 민감 정보 아님) |
| openFirewall | true | 포트 45876 자동 오픈 |
| environmentFile | 미사용 | sops 없이 environment 직접 설정 |
| flake input 추가 | 불필요 | nixpkgs 내장 모듈 사용 |

## 알려진 이슈

NixOS [#508301](https://github.com/NixOS/nixpkgs/issues/508301) — 25.11 systemd hardening이 간섭 가능.
배포 후 `sudo journalctl -u beszel-agent --since "1 min ago" --no-pager`로 확인 필요.

## 배포 명령

```bash
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
```
