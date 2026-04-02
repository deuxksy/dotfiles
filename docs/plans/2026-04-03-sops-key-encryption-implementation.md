# walle/.key SOPS 암호화 구현 계획

## Goal

walle/.key 파일의 민감한 API 키를 sops로 암호화하고, .zshrc에서 자동으로 복호화하여 로드

## Architecture
- sops를 사용한 in-place 암호화
- eval을 사용한 런타임 복호화 및 환경변수 로드
- 기존 .sops.yaml 설정 활용

## Tech Stack
- sops (Mozilla SOPS)
- age (Agnostic Encryption)
- zsh

---

## Task Structure

### Task 1: walle/.key 파일 암호화

**Files:**
- Modify: `walle/.key` (in-place encryption)

**Commands:**
```bash
sops -e -i walle/.key
```

**Expected Output:**
- 파일이 YAML 형식의 암호화된 데이터로 변경
- 기존 export 문들이 암호화된 값으로 변환

---

### Task 2: walle/.zshrc 수정
**Files:**
- Modify: `walle/.zshrc` (line 122)

**Changes:**
- Before: `. ~/.key`
- After: `eval "$(sops -d ~/.key)"`

**Commands:**
```bash
# 파일 수정 (Edit tool 사용)
```

**Expected Output:**
- .zshrc에서 평문 source 대신 sops 복호화 사용

---

### Task 3: 검증
**Commands:**
```bash
# 암호화 확인
file walle/.key

# 복호화 테스트
sops -d walle/.key

# 환경변수 확인 (새 shell에서)
echo $ANTHROPIC_API_KEY
```

**Expected Output:**
- file 명령: "YAML text" 출력
- sops -d: export 문들이 출력됨
- echo: API 키 값이 정상적으로 출력됨

---

## Execution Handoff
**Parallel Session** - 이 세션에서 직접 실행 (단순한 작업이므로)
