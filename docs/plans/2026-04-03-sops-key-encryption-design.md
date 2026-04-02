# walle/.key SOPS 암호화 설계

## 개요

`walle/.key` 파일의 민감한 API 키들을 sops로 암호화하고, `walle/.zshrc`에서 eval로 복호화하여 로드하도록 변경.

## 현재 상황

- `walle/.key`: API 키들이 평문으로 저장됨
- `.sops.yaml`: `.key` 파일 패턴이 이미 포함됨 (`path_regex: ^(secrets/.*|.*/\.key)$`)
- `walle/.zshrc`: `. ~/.key`로 source 중

## 설계

### 1. 파일 암호화

```bash
sops -e -i walle/.key
```

- in-place 암호화로 원본 파일을 암호화된 버전으로 대체
- `.sops.yaml` 규칙에 따라 age 키로 암호화됨

### 2. .zshrc 수정

**변경 전:**
```bash
. ~/.key
```

**변경 후:**
```bash
eval "$(sops -d ~/.key)"
```

### 3. 검증

```bash
file walle/.key  # expected: YAML text
sops -d walle/.key  # expected: export statements
```

## 보안 고려사항

- 암호화된 파일만 Git에 저장됨
- 복호화는 shell 시작 시 메모리에서만 수행
- age 키는 `~/.config/age/key.txt` 또는 환경변수로 관리됨
