# Hermes Agent — mo NixOS SRE Assistant

> **Date**: 2026-05-22
> **Status**: Draft
> **Host**: mo (NixOS, x86_64-linux)

## TL;DR

mo NixOS에 hermes-agent를 Native 모드(systemd)로 배포. Tailscale Aperture(`http://ai/v1`)를 AI Gateway로 사용하고 glm-5.1 모델 선택. Telegram으로 메시징 연결. sops-nix로 시크릿 관리. 두 번째 물리 서버에 역할 분담 에이전트 추가 예정.

## Architecture

```
Telegram ←── hermes gateway (systemd) ←── Tailscale Aperture (http://ai/v1) ←── glm-5.1
```

## Decisions

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| 배포 모드 | Native (systemd) | 보안 강화, 재현 가능, mo는 서버 전용 |
| 역할 | SRE / 인프라 어시스턴트 | mo에 k8s, Proxmox, 네트워크 도구 집중 |
| 메시징 | Telegram | 설정 간단, 봇 토큰만으로 연결 |
| AI Gateway | Tailscale Aperture | API 키 불필요, Tailscale 인증으로 처리 |
| 모델 | glm-5.1 | Z.ai 구독 플랜 |
| Secret 관리 | sops-nix | 기존 `.sops.yaml` + age 키 활용 |
| 모듈 분리 | `hosts/mo/hermes.nix` | 두 번째 호스트에 독립적 역할 분담 가능 |

## File Changes

### `nix/nixos/flake.nix`

- `sops-nix` input 추가
- `hermes-agent` input 추가
- outputs에 `sops-nix.nixosModules.sops` module import

### `nix/nixos/hosts/mo/hermes.nix` (신규)

```nix
{ config, ... }:
{
  sops.secrets."hermes-env" = {
    format = "yaml";
    sopsFile = ../../secrets/hermes.yaml;
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    settings = {
      model = {
        default = "glm-5.1";
        base_url = "http://ai/v1";
      };
      terminal = {
        backend = "local";
        timeout = 180;
      };
    };
  };
}
```

### `nix/nixos/hosts/mo/default.nix`

- `./hermes.nix` import 추가

### `secrets/hermes.yaml` (신규, sops 암호화)

```yaml
hermes-env: |
    TELEGRAM_BOT_TOKEN=<encrypted>
```

## Secrets

| Secret | 위치 | 암호화 |
| --- | --- | --- |
| TELEGRAM_BOT_TOKEN | `secrets/hermes.yaml` | sops + age |

- age 키: `~/.config/sops/age/keys.txt` (mo에 배치 필요)
- sops 설정: `.sops.yaml` (repo root, 이미 구성됨)

## Deployment

```bash
sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo
```

## Verification

```bash
systemctl status hermes-agent
hermes version
hermes config
# Telegram에서 @ZZiZiLY_MoBot에게 메시지 전송 → 응답 확인
```

## Future Work

- 두 번째 물리 서버에 개발 어시스턴트 에이전트 배포
- Discord 연결 추가 (OAuth 필요)
- SOUL.md로 SRE 페르소나 정의
- MCP 서버 추가 (k8sgpt, holmes 등)
