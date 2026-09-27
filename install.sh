#!/usr/bin/env bash
# dotfiles bootstrap - OS layer(stow/brew) + AI agent layer(apm)
# usage: ./install.sh <eve|axiom|bazzite|girl|auxo> [--dry-run]
set -euo pipefail

HOST="${1:?usage: ./install.sh <eve|axiom|bazzite|girl|auxo> [--dry-run]}"
DRY_RUN="${2:-}"
REPO="$(cd "$(dirname "$0")" && pwd)"

run() {
  if [[ "$DRY_RUN" == "--dry-run" ]]; then echo "[dry-run] $*"; else "$@"; fi
}

case "$HOST" in
  eve|axiom)   PKGS=(base "$HOST") ;;
  bazzite)     PKGS=(base bazzite) ;;   # mo
  girl|auxo)   PKGS=(base "$HOST") ;;
  *) echo "install.sh: unknown host '$HOST'" >&2; exit 1 ;;
esac

echo "==> [1/5] stow 배포: ${PKGS[*]}"
run mkdir -p "$HOME/.apm" "$HOME/.claude"
run stow --no-folding -d "$REPO" -t ~ "${PKGS[@]}"
# 호스트에 실재하는 ~/.claude/settings.json이 있으면 백업 후 stow 소유로 전환
if [[ ! -L "$HOME/.claude/settings.json" && -f "$HOME/.claude/settings.json" && "$DRY_RUN" != "--dry-run" ]]; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak-$(date +%Y%m%d%H%M%S)"
  rm "$HOME/.claude/settings.json"
  stow --no-folding -R -d "$REPO" -t ~ "${PKGS[@]}"
fi

echo "==> [2/5] brew bundle (brew 있는 호스트)"
if command -v brew >/dev/null 2>&1; then
  run brew bundle -g
elif [[ "$HOST" == "girl" || "$HOST" == "auxo" ]]; then
  echo "    (brew 없음 — mise/apt는 수동, apm은 다음 단계에서 curl 설치)"
fi

echo "==> [3/5] apm CLI"
if ! command -v apm >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    run brew install apm
  else
    run bash -c 'curl -sSL https://aka.ms/apm-unix | sh'
  fi
fi

echo "==> [4/5] sops 키 확인"
if [[ -f "$HOME/.key" ]] && command -v sops >/dev/null 2>&1; then
  sops -d "$HOME/.key" >/dev/null 2>&1 && echo "    sops 복호화 OK" || echo "    (경고) ~/.key 복호화 실패 — MCP 인증 env는 미설정"
else
  echo "    (건너뜀) ~/.key 없음 — 신규 호스트면 age key 복원 먼저"
fi

echo "==> [5/5] apm install -g (AI agent layer)"
run apm install -g --frozen || { echo "    frozen 실패 — lock 갱신 필요. 'apm install -g' 후 lock 커밋"; run apm install -g; }

# apm이 symlink를 rename으로 교체할 수 있음(R8) — 무결성 복구
if [[ "$DRY_RUN" != "--dry-run" ]]; then
  if [[ ! -L "$HOME/.apm/apm.yml" ]]; then
    cp "$HOME/.apm/apm.yml" "$HOME/.apm/apm.yml.bak-$(date +%Y%m%d%H%M%S)"
    rm -f "$HOME/.apm/apm.yml"; stow --no-folding -R -d "$REPO" -t ~ "${PKGS[@]}"
    echo "    ~/.apm/apm.yml symlink 복구"
  fi
  if [[ -f "$HOME/.apm/apm.lock.yaml" && ! -L "$HOME/.apm/apm.lock.yaml" ]]; then
    cp "$HOME/.apm/apm.lock.yaml" "$REPO/base/.apm/apm.lock.yaml"
    rm "$HOME/.apm/apm.lock.yaml"
    stow --no-folding -R -d "$REPO" -t ~ "${PKGS[@]}"
    echo "    apm.lock.yaml repo 이관·symlink 복구 (변경분 커밋 필요)"
  fi
fi

echo "완료. 첫 claude 세션에서 plugin이 자동 설치됩니다. provider 전환: claude-profile zai|kimi|aperture"
