# apm Agent Layer — Phase 0 검증 기록

> **Date**: 2026-09-27 · **Host**: eve (macOS) · **apm**: 0.32.0 (Homebrew)
> 대상 spec: [2026-09-27-apm-agent-layer-design.md](../../okf/explanation/2026-09-27-apm-agent-layer-design.md) 리스크 표 #1~#8의 실측 결과

## R1. `mcp:` manifest 스키마 확정 (리스크 #1 해소)

CLI(`apm install -g --mcp ... --transport stdio ...`)가 생성한 실측 YAML:

```yaml
dependencies:
  mcp:
  - name: zai-mcp-server
    registry: false          # self-defined 선언. registry 해석 시 true + registry URL
    transport: stdio         # stdio | http | sse | streamable-http
    command: npx
    args:
    - -y
    - '@z_ai/mcp-server'
    env:
      Z_AI_API_KEY: ${Z_AI_API_KEY}
```

- `${VAR}` placeholder 보존 확인
- **env에 선언하지 않은 기존 키는 배포 시 소실** (Z_AI_MODE 삭제 관찰) → manifest에 `Z_AI_MODE` 리터럴 포함 필수

## R2. lock 파일 형식

`apm.lock.yaml`: `lockfile_version: '1'`, `apm_version`, `deployments[]`(kind/target/value/runtime/scope/owners), `mcp_servers[]`, `mcp_configs`(엔트리 전체), `mcp_target_servers`(runtime별).

## R3. `~/.claude.json` merge 안전성 (리스크 #3 해소)

동일 이름 엔트리는 **entry-wise overwrite** — zai-mcp-server만 교체되고 나머지 5개(aperture, serena, web-reader, web-search-prime, zread) 무손상. 기존 수동 항목의 별도 제거 불필요(apm 재배포가 덮어씀). Task 3의 동등성 diff 검증은 유지.

## R4. 런타임별 write 위치 실측 (리스크 #4 해소)

| runtime | write 위치 | 비고 |
| :--- | :--- | :--- |
| claude | `~/.claude.json` `mcpServers` | 기존 타 서버 보존 |
| codex | `~/.codex/config.toml` `[mcp_servers.<name>]` + `.env` 서브테이블 | 기존 mcp_servers 블록 보존 |
| gemini | `~/.gemini/settings.json` `mcpServers` | **머신 로컬 실재 파일** (inventory 정정: stow 아님 — `base/.gemini/settings.json`은 git에 없음) |
| kiro | `~/.kiro/settings/mcp.json` | 미설치 런타임도 생성됨 |
| vscode | user scope skip | "workspace-only runtimes" 안내 정상 |

targets 미지정 시 kiro까지 자동 configure됨 → manifest `targets: [claude, codex, gemini]` 핀 필수 (계획대로 유지).

## R5. `--dry-run` 배치 사고 및 원복 기록

`--`(stdio command 구분자) **뒤의** `--dry-run`은 apm 플래그가 아닌 서버 인자가 되어 우발 실설치 발생. 원복 완료:

- `~/.claude.json`: 백업 복원 (zai 엔트리 원문 복원 확인)
- `~/.codex/config.toml`: zai block 제거 (grep 0건)
- `~/.gemini/settings.json`: `mcpServers` 제거 (oauth 설정만 잔존)
- `~/.kiro/`: 사고 시점(16:34) 신규 생성이라 통째 삭제
- `~/.apm/{apm.yml, apm.lock.yaml, .apm-lifecycle.lock}`: 우발 생성분 삭제 (사전 존재 cache/, config.json, marketplaces.* 보존)

백업: `~/.claude.json.bak-phase0`, `~/.claude/settings.json.bak-phase0`

교훈: apm 플래그는 반드시 `--` 앞에 위치.

## R6. zai-coding-plugins 마켓 판정 (리스크 #6 해소)

이미 선언적으로 표현되어 있음 — 채택:

```json
"zai-coding-plugins": {
  "source": {"source": "directory", "path": "/Users/crong/.claude/plugins/vendor/zai-coding-plugins"},
  "autoUpdate": true
}
```

신규 장비는 vendor 디렉토리 선공급 필요(수동 단계) → Phase 2/3 런북에 기재. 차후 `ai-agent-skill` repo 미러링은 Future work.

## R7. 기타 관찰

- apm이 org policy repo(`deuxksy/.github-private`) 조회 시도 → WARNING 출력(무해). 반복 시 `apm config` 비활성화 검토
- 리스크 #7(enabled:false plugin 첫 세션 설치 여부), #8(kyolim codex/gemini 미설치 거동)는 Task 5 / Phase 3 실행 시점 검증 (각각 verify step 존재)

## R8. symlink 교체 실증 (리스크 #2 확정 — Task 2 실행 중)

- **CLI package-arg install**(`apm install -g <pkg>`)은 manifest를 갱신하며, 그 쓰기가 **rename이라 symlink를 실체 파일로 교체**한다. 이후 repo 편집이 apm과 분리되어 엔트리가 누적하는 사고 관찰
- **plain install**(`apm install -g`)은 manifest를 재작성하지 않아 symlink 유지 확인
- 운영 규칙: manifest를 건드리는 CLI 실행 후 `ls -la ~/.apm/apm.yml`로 symlink 확인 → 교체 시 `stow --no-folding -R -t ~ base` 복구. `install.sh`에 동일 점검 포함 (Task 7)

## R9. microsoft/azure-skills 제외 (Task 2 ruling)

- apm 0.32.0이 azure-skills 루트 패키지 적분 시 `Object of type mappingproxy is not JSON serializable` crash — manifest 형식 3종(`git:` 루트, `skills:` 필터, `git:`+`path:`, path 축약) 전부 동일 실패
- CLI-arg 형식(`apm install -g microsoft/azure-skills/skills/microsoft-foundry`)만 작동하나 manifest 재현 불가 + stale lock reconciliation이 계속 재적분하므로 **manifest에서 제외**하고 배포본도 제거
- 재설치(필요 시): `apm install -g microsoft/azure-skills/skills/microsoft-foundry` 후 lock·symlink 상태 점검. apm 상류 수정 후 manifest 재추가 권장 (microsoft/apm 이슈 후보)
- 결과: manifest는 외부 skill 2종(firecrawl/anydoc, vercel-labs/skills)로 확정
