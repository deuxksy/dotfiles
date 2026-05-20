# 패키지 매니저

- `SDK` 관리는 `mise` 를 사용 한다. 단, NixOS(mo)에서는 mise를 사용하지 않음 — 모든 도구는 Nix 패키지로 관리
- `Node Package Manager`는 `pnpm`, `pnpx` 를 사용 한다. 단, NixOS(mo)에서는 `npm install -g` 불가 — pnpm 글로벌 사용
- `Python Package Manager`는 `uv` 를 사용 한다.
