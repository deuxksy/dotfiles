# Hermes Agent mo NixOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** mo NixOS에 hermes-agent를 Native 모드로 배포하고 Telegram 봇(@ZZiZiLY_MoBot)과 연결.

**Architecture:** flake.nix에 sops-nix + hermes-agent 입력 추가 후, hosts/mo/hermes.nix 분리 모듈에서 서비스 선언. Tailscale Aperture(http://ai/v1) → glm-5.1 모델 사용. Telegram Bot Token은 sops + age로 암호화.

**Tech Stack:** NixOS Flakes, sops-nix, hermes-agent NixOS Module, Tailscale Aperture, Telegram Bot API

---

## File Structure

| File | Action | Responsibility |
| --- | --- | --- |
| `nix/nixos/flake.nix` | Modify | sops-nix, hermes-agent flake inputs 추가, module import |
| `nix/nixos/hosts/mo/default.nix` | Modify | hermes.nix import 추가 |
| `nix/nixos/hosts/mo/hermes.nix` | Create | hermes-agent 서비스 + sops secret 설정 |
| `nix/nixos/secrets/hermes.yaml` | Move | sops 암호화된 Telegram Bot Token |
| `.sops.yaml` | Modify | nix/nixos/secrets/ 경로 규칙 추가 |
| `secrets/hermes.yaml` | Delete | nix/nixos/secrets/로 이동 후 제거 |

---

### Task 1: sops Secret 파일 이동 및 .sops.yaml 업데이트

**Files:**
- Move: `secrets/hermes.yaml` → `nix/nixos/secrets/hermes.yaml`
- Modify: `.sops.yaml`

- [ ] **Step 1: nix/nixos/secrets 디렉토리 생성**

```bash
mkdir -p nix/nixos/secrets
```

- [ ] **Step 2: 기존 암호화 파일 이동**

```bash
mv secrets/hermes.yaml nix/nixos/secrets/hermes.yaml
```

- [ ] **Step 3: .sops.yaml에 nix/nixos/secrets 경로 규칙 추가**

기존 `.sops.yaml`:
```yaml
keys:
  - &crong age1qw643dna4spaup6sr5ap0jf039ncjd54e8ekvrfy6p6x96ys2y4qn5vcsy

creation_rules:
  - path_regex: ^(secrets/.*|.*/\.key)$
    key_groups:
      - age:
          - *crong
```

변경 후 `.sops.yaml`:
```yaml
keys:
  - &crong age1qw643dna4spaup6sr5ap0jf039ncjd54e8ekvrfy6p6x96ys2y4qn5vcsy

creation_rules:
  - path_regex: ^(secrets/.*|nix/nixos/secrets/.*|.*/\.key)$
    key_groups:
      - age:
          - *crong
```

- [ ] **Step 4: 복호화 검증**

Run: `sops -d nix/nixos/secrets/hermes.yaml`
Expected: `TELEGRAM_BOT_TOKEN=8912613028:...` 출력

- [ ] **Step 5: 빈 secrets 디렉토리 정리**

```bash
rmdir secrets 2>/dev/null || true
```

- [ ] **Step 6: Commit**

```bash
git add .sops.yaml nix/nixos/secrets/hermes.yaml
git rm secrets/hermes.yaml 2>/dev/null || true
git commit -m "feat(mo): add sops-encrypted hermes secret and update path rules"
```

---

### Task 2: flake.nix에 sops-nix, hermes-agent 입력 추가

**Files:**
- Modify: `nix/nixos/flake.nix`

- [ ] **Step 1: flake.nix 수정**

기존 `inputs` 블록에 2개 입력 추가, `outputs`에 module import 추가:

```nix
{
  description = "Crong's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, hermes-agent }: {
    nixosConfigurations."mo" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/mo/default.nix
        sops-nix.nixosModules.sops
        hermes-agent.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.crong = import ./home/crong.nix;
        }
      ];
    };
  };
}
```

- [ ] **Step 2: Flake lock 업데이트**

Run: `cd nix/nixos && nix flake lock --update-input sops-nix --update-input hermes-agent`
Expected: sops-nix, hermes-agent 해시 다운로드, flake.lock 갱신

- [ ] **Step 3: Flake eval 검증**

Run: `cd nix/nixos && nix flake check --no-build`
Expected: 에러 없이 완료

- [ ] **Step 4: Commit**

```bash
git add nix/nixos/flake.nix nix/nixos/flake.lock
git commit -m "feat(mo): add sops-nix and hermes-agent flake inputs"
```

---

### Task 3: hermes.nix 모듈 생성

**Files:**
- Create: `nix/nixos/hosts/mo/hermes.nix`

- [ ] **Step 1: hermes.nix 작성**

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

- [ ] **Step 2: default.nix에 import 추가**

`nix/nixos/hosts/mo/default.nix`의 imports 블록에 `./hermes.nix` 추가:

```nix
  imports = [
    ./hardware-configuration.nix
    ./hermes.nix
    ../../modules/desktop/kde.nix
    ../../modules/virtualization.nix
  ];
```

- [ ] **Step 3: Flake eval 재검증**

Run: `cd nix/nixos && nix flake check --no-build`
Expected: 에러 없이 완료

- [ ] **Step 4: Commit**

```bash
git add nix/nixos/hosts/mo/hermes.nix nix/nixos/hosts/mo/default.nix
git commit -m "feat(mo): add hermes-agent NixOS module with sops secret"
```

---

### Task 4: NixOS 배포 및 서비스 검증

- [ ] **Step 1: nixos-rebuild switch**

Run: `sudo nixos-rebuild switch --flake ~/git/dotfiles/nix/nixos#mo`
Expected: 빌드 성공, 서비스 활성화

- [ ] **Step 2: 서비스 상태 확인**

Run: `systemctl status hermes-agent`
Expected: `active (running)`

- [ ] **Step 3: CLI 버전 확인**

Run: `hermes version`
Expected: hermes-agent 버전 출력

- [ ] **Step 4: 설정 확인**

Run: `hermes config`
Expected: model.default = "glm-5.1", model.base_url = "http://ai/v1"

- [ ] **Step 5: Telegram 봇 연동 테스트**

Telegram에서 @ZZiZiLY_MoBot에게 메시지 전송 → 에이전트 응답 확인

---

### Task 5: 최종 Commit 및 정리

- [ ] **Step 1: 스펙 문서 상태 업데이트**

`docs/superpowers/specs/2026-05-22-hermes-agent-mo-design.md`의 Status를 `Approved`로 변경

- [ ] **Step 2: 최종 Commit**

```bash
git add docs/superpowers/specs/2026-05-22-hermes-agent-mo-design.md
git commit -m "docs(mo): approve hermes-agent design spec"
```
